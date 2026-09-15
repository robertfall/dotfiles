#!/usr/bin/env bash
# Diagnose and repair the desktop-portal stack that screen sharing runs on.
#
# The chain is: app -> xdg-desktop-portal (frontend, owns the D-Bus name)
# -> xdg-desktop-portal-hyprland (backend, draws the picker and talks
# Hyprland's screencopy protocol) -> pipewire (carries the frames).
# Any link can die on its own, so the stages below escalate: each one is a
# superset of the damage the previous one repairs.
#
# Two facts drive the whole design:
#
#   1. xdg-desktop-portal.service has Requisite=graphical-session.target.
#      If that target is inactive the unit refuses to start, and no amount
#      of restarting fixes it. The target only activates because the session
#      was launched through uwsm (the "Hyprland (uwsm)" GDM entry). A dead
#      target means the wrong session entry was picked at login -- a relog,
#      not a restart.
#
#   2. The backend needs HYPRLAND_INSTANCE_SIGNATURE and WAYLAND_DISPLAY to
#      match the *live* compositor. If Hyprland restarted without the systemd
#      user environment following, the backend cheerfully connects to a dead
#      socket and the picker never appears. This script never trusts the
#      caller's environment for those; `hyprctl instances` works without any
#      env at all, so we always read the truth from the compositor itself.
#      That matters because this is often run from a tmux pane whose env was
#      inherited from an ssh login and is months stale.
#
# Usage: portal-repair.sh [check|soft|env|pipewire|hard]   (default: check)
set -uo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

ok()   { printf '  \033[32mOK\033[0m    %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; }
warn() { printf '  \033[33mWARN\033[0m  %s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# Read the live compositor identity straight from Hyprland. Falls back to
# nothing rather than to a guess -- a wrong signature is worse than none.
live_sig=$(hyprctl instances 2>/dev/null | sed -n 's/^instance \(.*\):$/\1/p' | head -1)
live_sock=$(hyprctl instances 2>/dev/null | sed -n 's/^[[:space:]]*wl socket: //p' | head -1)

PORTAL_UNITS=(xdg-desktop-portal-hyprland.service xdg-desktop-portal.service)
PW_UNITS=(wireplumber.service pipewire.service pipewire-pulse.service)

do_check() {
  local fail=0
  step "Compositor"
  if [[ -n $live_sig ]]; then
    ok "Hyprland live: $live_sig (socket $live_sock)"
  else
    bad "no live Hyprland instance -- nothing here will help"; return 1
  fi

  step "Session target"
  if systemctl --user -q is-active graphical-session.target; then
    ok "graphical-session.target active (session went through uwsm)"
  else
    bad "graphical-session.target INACTIVE"
    echo "        xdg-desktop-portal.service cannot start without it."
    echo "        Fix: log out, pick 'Hyprland (uwsm)' at GDM. See stage 'hard' for a stopgap."
    fail=1
  fi

  step "Services"
  for u in "${PORTAL_UNITS[@]}" "${PW_UNITS[@]}"; do
    if systemctl --user -q is-active "$u"; then ok "$u"; else bad "$u is $(systemctl --user is-active "$u" 2>&1)"; fail=1; fi
  done

  step "Session environment seen by the services"
  local sys_sig sys_sock
  sys_sig=$(systemctl --user show-environment | sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p')
  sys_sock=$(systemctl --user show-environment | sed -n 's/^WAYLAND_DISPLAY=//p')
  if [[ $sys_sig == "$live_sig" ]]; then ok "HYPRLAND_INSTANCE_SIGNATURE matches the live compositor"
  else bad "signature STALE: systemd has '${sys_sig:-<unset>}', live is '$live_sig'"; fail=1; fi
  if [[ $sys_sock == "$live_sock" ]]; then ok "WAYLAND_DISPLAY matches ($live_sock)"
  else bad "WAYLAND_DISPLAY stale: systemd has '${sys_sock:-<unset>}', live is '$live_sock'"; fail=1; fi

  # The running backend keeps whatever env it started with, so check the
  # process too -- systemd's env can be correct while the process is stale.
  local pid
  pid=$(systemctl --user show -p MainPID --value xdg-desktop-portal-hyprland.service 2>/dev/null)
  if [[ -n $pid && $pid != 0 && -r /proc/$pid/environ ]]; then
    local proc_sig
    proc_sig=$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p')
    if [[ $proc_sig == "$live_sig" ]]; then ok "running backend (pid $pid) is on the live compositor"
    else bad "running backend (pid $pid) holds STALE signature '$proc_sig'"; fail=1; fi
  fi

  step "Live portal on D-Bus"
  local types
  types=$(busctl --user get-property org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
            org.freedesktop.portal.ScreenCast AvailableSourceTypes 2>&1)
  if [[ $types == u\ * ]]; then
    ok "ScreenCast answers: AvailableSourceTypes = ${types#u }  (1=monitor 2=window 4=virtual)"
  else
    bad "ScreenCast did not answer: $types"; fail=1
  fi

  step "Verdict"
  if (( fail == 0 )); then
    echo "  Healthy. Do not touch anything."
  else
    echo "  Broken. Run: $0 soft      (fastest, keeps audio)"
    echo "  Then:        $0 env       (if the signature was stale)"
    echo "  Then:        $0 pipewire  (only if frames are black -- THIS DROPS AUDIO)"
  fi
  return $fail
}

# Stage 1. Restarts only the portal pair. Roughly two seconds, does not
# touch audio, safe to run while a call is connected. Reconnect the share
# in the app afterwards; the app keeps its old session otherwise.
do_soft() {
  step "soft: restarting the portal pair"
  systemctl --user restart xdg-desktop-portal-hyprland.service && ok "backend restarted" || bad "backend restart failed"
  systemctl --user restart xdg-desktop-portal.service && ok "frontend restarted" || {
    bad "frontend restart failed -- almost always graphical-session.target being inactive"
    systemctl --user is-active graphical-session.target
  }
  sleep 1
}

# Stage 2. Re-seeds the session environment from the live compositor, then
# does stage 1 so the services actually pick it up. Needed after Hyprland
# has been restarted underneath a session that kept running.
do_env() {
  step "env: re-seeding the session environment"
  [[ -z $live_sig ]] && { bad "no live compositor to read from"; return 1; }
  export HYPRLAND_INSTANCE_SIGNATURE="$live_sig" WAYLAND_DISPLAY="$live_sock" \
         XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_TYPE=wayland
  systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && ok "systemd environment updated"
  dbus-update-activation-environment --systemd HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY && ok "dbus activation environment updated"
  do_soft
}

# Stage 3. PipeWire carries the actual frames. Restart it when the picker
# appears and the share starts but the far end sees black or a frozen frame.
# This drops every audio stream on the machine for a second or two, so it is
# deliberately not part of 'soft'.
do_pipewire() {
  step "pipewire: restarting the media stack (AUDIO WILL DROP)"
  systemctl --user restart "${PW_UNITS[@]}" && ok "pipewire stack restarted" || bad "pipewire restart failed"
  sleep 1
  do_soft
}

# Stage 4. Everything, in dependency order. If graphical-session.target is
# inactive this also runs the backend by hand as a transient scope, which is
# a stopgap to save a call in progress -- it is not a fix. Relog through the
# uwsm entry afterwards.
do_hard() {
  do_env
  do_pipewire
  if ! systemctl --user -q is-active graphical-session.target; then
    step "hard: graphical-session.target is dead -- hand-launching the portal"
    warn "stopgap only. Relog via the 'Hyprland (uwsm)' GDM entry when the call ends."
    systemctl --user stop "${PORTAL_UNITS[@]}" 2>/dev/null
    systemd-run --user --scope --collect -E HYPRLAND_INSTANCE_SIGNATURE="$live_sig" \
      -E WAYLAND_DISPLAY="$live_sock" -E XDG_CURRENT_DESKTOP=Hyprland \
      /usr/libexec/xdg-desktop-portal-hyprland >/dev/null 2>&1 &
    sleep 1
    systemd-run --user --scope --collect -E XDG_CURRENT_DESKTOP=Hyprland \
      /usr/libexec/xdg-desktop-portal >/dev/null 2>&1 &
    sleep 2
    ok "hand-launched; re-run '$0 check' to confirm ScreenCast answers"
  fi
}

case "${1:-check}" in
  check)    do_check ;;
  soft)     do_soft; echo; do_check ;;
  env)      do_env; echo; do_check ;;
  pipewire) do_pipewire; echo; do_check ;;
  hard)     do_hard; echo; do_check ;;
  *) echo "Usage: $0 [check|soft|env|pipewire|hard]" >&2; exit 2 ;;
esac

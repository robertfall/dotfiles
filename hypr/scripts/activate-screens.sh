#!/usr/bin/env bash
# Bring the screens back when Hyprland is alive but the outputs stayed dark
# after a DPMS off (hypridle's on-resume did not fire, 2026-09-14). Meant to
# be run from a TTY, so it finds the Hyprland instance itself.
#
# A DPMS request is only applied while Hyprland's VT (tty2) is active; from
# another VT aquamarine logs "drm: Session inactive" and drops it. So: send
# `dpms on` now, then wait for tty2 to become active and force a full
# off/on cycle there. The cycle also clears the nvidia black-after-VT-switch
# frame. Usage: activate-screens [MAX_WAIT_SECONDS]
set -uo pipefail

wait_max=${1:-90}
hypr_vt=tty2

export HYPRLAND_INSTANCE_SIGNATURE
HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "/run/user/$(id -u)/hypr" 2>/dev/null | head -1)
[[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] || { echo "No running Hyprland instance found" >&2; exit 1; }

# Keep the log before anyone reboots; it is on tmpfs.
cp "/run/user/$(id -u)/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log" "$HOME/hyprland-black-$(date +%Y%m%d-%H%M%S).log" 2>/dev/null

active() { cat /sys/class/tty/tty0/active; }

timeout 5 hyprctl dispatch dpms on >/dev/null || { echo "hyprctl did not answer; Hyprland may be stuck" >&2; exit 1; }
echo "dpms on sent (Hyprland's own state is now 'on')."

if [[ $(active) != "$hypr_vt" ]]; then
    echo "Switch to $hypr_vt now (Ctrl+Alt+F2). Waiting up to ${wait_max}s to force a modeset there..."
    for ((i = 0; i < wait_max * 2; i++)); do
        [[ $(active) == "$hypr_vt" ]] && break
        sleep 0.5
    done
    [[ $(active) == "$hypr_vt" ]] || { echo "$hypr_vt never became active; run again once you are on it." >&2; exit 1; }
    sleep 2
fi

timeout 5 hyprctl dispatch dpms off >/dev/null
sleep 2
timeout 5 hyprctl dispatch dpms on >/dev/null
sleep 2
timeout 5 hyprctl monitors | grep -E "^Monitor|dpmsStatus"

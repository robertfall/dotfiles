#!/usr/bin/env bash
# Force Hyprland to redo modesetting on a monitor that Hyprland/DRM still
# think is enabled but has gone physically blank (e.g. an nvidia HDMI FRL
# link-training failure after the display power-cycles itself). A plain
# `hyprctl dispatch dpms on` or `hyprctl reload` doesn't help here because
# nothing actually tore down the output; disabling it first forces a real
# teardown/recreate, which retriggers link training on re-enable.
#
# Retraining is not reliable. When FRL fails the driver prunes every mode
# needing FRL bandwidth (4K@120 wants 1188 MHz; TMDS caps at 594 MHz), so
# re-enabling at the configured mode matches nothing and leaves the output
# disabled with DPMS off — a black screen, which is worse than the blank we
# came to fix. So verify the connector really came back, and fall back to the
# fastest mode the driver still offers.
#
# No `set -e`: the retry and fallback paths need to see failures, not die on
# them. Bound to SUPER+SHIFT+T. Usage: kick-monitor.sh [MONITOR_NAME]
set -uo pipefail

monitor="${1:-HDMI-A-1}"
conf="$HOME/.config/hypr/hyprland.conf"

drm=$(echo /sys/class/drm/card*-"$monitor")
[[ -d $drm ]] || { echo "No DRM connector found for $monitor" >&2; exit 1; }

mode_line=$(grep -m1 "^monitor = ${monitor}," "$conf") || {
    echo "No 'monitor = ${monitor},...' line found in $conf" >&2
    exit 1
}
rule=${mode_line#monitor = }               # HDMI-A-1,3840x2160@120,2560x0,1.25
IFS=, read -r _ mode rest <<<"$rule"       # mode=3840x2160@120  rest=2560x0,1.25
res=${mode%@*}

# Read the mode list before disabling — once the output is down it is gone.
modes=$(hyprctl monitors all |
    awk -v m="^Monitor ${monitor} " '$0 ~ m {f=1} f && /availableModes:/ {
        sub(/.*availableModes: /, ""); print; exit }')

alive() { [[ $(<"$drm/enabled") == enabled && $(<"$drm/dpms") == On ]]; }

# Re-enable at $1 and report whether the connector actually lit up.
apply() {
    hyprctl keyword monitor "${monitor},${1},${rest}" >/dev/null
    sleep 3
    alive
}

kick() {
    hyprctl keyword monitor "${monitor},disable" >/dev/null
    sleep "$1"
}

kick 2 && apply "$mode" && exit 0
kick 5 && apply "$mode" && exit 0          # a longer drop sometimes retrains

# FRL stayed down. Take the fastest mode still on offer at this resolution so
# there is a picture, and say so rather than silently sitting at half rate.
best=$(tr ' ' '\n' <<<"$modes" | grep -o "^${res}@[0-9.]\+" | sort -t@ -k2 -g | tail -1)
if [[ -n $best ]] && apply "$best"; then
    notify-send "$monitor" "FRL retrain failed — at ${best#*@}Hz, not ${mode#*@}Hz"
    exit 0
fi

notify-send -u critical "$monitor" "Did not come back. Try: hyprctl keyword monitor ${monitor},preferred,${rest}"
echo "$monitor did not come back after the kick" >&2
exit 1

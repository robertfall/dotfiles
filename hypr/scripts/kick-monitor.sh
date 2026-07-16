#!/usr/bin/env bash
# Force Hyprland to redo modesetting on a monitor that Hyprland/DRM still
# think is enabled but has gone physically blank (e.g. an nvidia HDMI FRL
# link-training failure after the display power-cycles itself). A plain
# `hyprctl dispatch dpms on` or `hyprctl reload` doesn't help here because
# nothing actually tore down the output; disabling it first forces a real
# teardown/recreate, which retriggers link training on re-enable.
# Bound to SUPER+SHIFT+T. Usage: kick-monitor.sh [MONITOR_NAME]
set -euo pipefail

monitor="${1:-HDMI-A-1}"
conf="$HOME/.config/hypr/hyprland.conf"

mode_line=$(grep -m1 "^monitor = ${monitor}," "$conf") || {
    echo "No 'monitor = ${monitor},...' line found in $conf" >&2
    exit 1
}
mode_args=${mode_line#monitor = }

hyprctl keyword monitor "${monitor},disable"
sleep 1
hyprctl keyword monitor "$mode_args"

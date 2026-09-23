#!/usr/bin/env bash
# Screenshot helper for the Hyprland binds.
#   screenshot.sh <full|region|window> [save]
# full   -> the focused monitor
# region -> drag a rectangle with slurp
# window -> click a visible window (geometry comes from hyprctl)
# The image always goes to the clipboard. With "save" it also goes to $dir.
set -euo pipefail

mode=${1:?usage: screenshot.sh <full|region|window> [save]}
save=${2:-}
dir=~/Pictures/Screenshots

case "$mode" in
  full)
    output=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
    grab=(grim -o "$output")
    ;;
  region)
    geom=$(slurp) || exit 0
    grab=(grim -g "$geom")
    ;;
  window)
    # Only windows on a workspace that is showing on some monitor.
    visible=$(hyprctl monitors -j | jq '[.[] | .activeWorkspace.id, .specialWorkspace.id]')
    geom=$(hyprctl clients -j \
      | jq -r --argjson v "$visible" \
          '.[] | select(.mapped and (.workspace.id as $w | $v | index($w)))
           | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.title)"' \
      | slurp -r) || exit 0
    grab=(grim -g "$geom")
    ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac

if [ "$save" = save ]; then
  mkdir -p "$dir"
  "${grab[@]}" -t png - | tee "$dir/$(date +%Y%m%d-%H%M%S).png" | wl-copy --type image/png
else
  "${grab[@]}" -t png - | wl-copy --type image/png
fi

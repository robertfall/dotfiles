#!/usr/bin/env bash
# Scroll handler for image#usdzar-spark: cycles its persisted range (up =
# longer, down = shorter) then signals waybar to re-run the exec immediately
# instead of waiting for the next interval tick.

range_file="$HOME/.cache/waybar-forex/usdzar-range"
mkdir -p "$(dirname "$range_file")"
ranges=(day month 6month year)

current=$(cat "$range_file" 2>/dev/null)
idx=0
for i in "${!ranges[@]}"; do
  [ "${ranges[$i]}" = "$current" ] && idx=$i
done

case "$1" in
  up)   idx=$(( (idx + 1) % ${#ranges[@]} )) ;;
  down) idx=$(( (idx - 1 + ${#ranges[@]}) % ${#ranges[@]} )) ;;
esac

echo "${ranges[$idx]}" > "$range_file"
pkill -RTMIN+9 waybar

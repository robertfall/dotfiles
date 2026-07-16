#!/usr/bin/env bash
# Calculator + live currency via fuzzel + qalc (libqalculate). Bound to SUPER+C.
# Type an expression, Enter to compute, Enter again to copy the result.
#   examples:  100 usd to eur    sqrt(2)*3    15% of 240    2 GiB to MB
# First-time forex: run `qalc -e` once in a terminal to download exchange rates.

input=$(: | fuzzel --dmenu --prompt='ƒ ' --placeholder='100 usd to eur') || exit 0
[ -n "$input" ] || exit 0

result=$(qalc -t -- "$input" 2>&1)

# Show "expr = result"; selecting the line (Enter) copies the result. Esc cancels.
printf '%s = %s\n' "$input" "$result" \
  | fuzzel --dmenu --prompt='↵ copy ' >/dev/null && printf '%s' "$result" | wl-copy

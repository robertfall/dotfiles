#!/usr/bin/env bash
# Calculator + live currency via fuzzel + qalc (libqalculate). Bound to SUPER+C.
# Type an expression, Enter to compute, Enter again to copy the result.
#   examples:  100 usd to eur    sqrt(2)*3    15% of 240    2 GiB to MB
# First-time forex: run `qalc -e` once in a terminal to download exchange rates.
# A plain "<amount> <CCY> to <CCY>" query is resolved via Wise's live
# mid-market rate instead of qalc's once-daily ECB cache; qalc's own engine
# can't be pointed at Wise directly (it only understands ECB's XML feed), so
# anything qalc-specific -- math, units, compound expressions -- still goes
# through qalc as before.

input=$(: | fuzzel --dmenu --prompt='ƒ ' --placeholder='100 usd to eur') || exit 0
[ -n "$input" ] || exit 0

result=""
shopt -s nocasematch
if [[ "$input" =~ ^([0-9]+(\.[0-9]+)?)[[:space:]]+([a-z]{3})[[:space:]]+to[[:space:]]+([a-z]{3})[[:space:]]*$ ]]; then
  amount="${BASH_REMATCH[1]}"
  from="${BASH_REMATCH[3]^^}"
  to="${BASH_REMATCH[4]^^}"
  rate=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $(cat "$HOME/.config/wise/token" 2>/dev/null)" \
    "https://api.transferwise.com/v1/rates?source=$from&target=$to" \
    2>/dev/null | jq -r '.[0].rate // empty' 2>/dev/null)
  if [ -n "$rate" ]; then
    result=$(awk -v a="$amount" -v r="$rate" -v c="$to" 'BEGIN { printf "%s %.2f (via Wise)", c, a * r }')
  fi
fi
shopt -u nocasematch

[ -n "$result" ] || result=$(qalc -t -- "$input" 2>&1)

# Show "expr = result"; selecting the line (Enter) copies the result. Esc cancels.
printf '%s = %s\n' "$input" "$result" \
  | fuzzel --dmenu --prompt='↵ copy ' >/dev/null && printf '%s' "$result" | wl-copy

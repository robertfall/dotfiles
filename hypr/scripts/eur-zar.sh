#!/usr/bin/env bash
# EUR->ZAR rate for waybar's custom/eurzar module. Reuses qalc (already set
# up for forex in calc.sh) rather than hitting an API directly.

rate=$(qalc -t -- "1 EUR to ZAR" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)

if [ -z "$rate" ]; then
  printf '{"text": "EUR/ZAR --", "tooltip": "qalc lookup failed -- no cached rate or no network"}\n'
  exit 0
fi

formatted=$(printf '%.2f' "$rate")
printf '{"text": "\xe2\x82\xac1 = R%s", "tooltip": "1 EUR = %s ZAR (via qalc)"}\n' "$formatted" "$formatted"

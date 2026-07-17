#!/usr/bin/env bash
# USD->ZAR rate for waybar's custom/usdzar module. Reuses qalc (already set
# up for forex in calc.sh) rather than hitting an API directly.

rate=$(qalc -t -- "1 USD to ZAR" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)

if [ -z "$rate" ]; then
  printf '{"text": "USD/ZAR --", "tooltip": "qalc lookup failed -- no cached rate or no network"}\n'
  exit 0
fi

formatted=$(printf '%.2f' "$rate")
printf '{"text": "$1 = R%s", "tooltip": "1 USD = %s ZAR (via qalc)"}\n' "$formatted" "$formatted"

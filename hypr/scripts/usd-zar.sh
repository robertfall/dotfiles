#!/usr/bin/env bash
# USD->ZAR rate for waybar's custom/usdzar module. Wise's mid-market rate
# moves through the trading day, unlike ECB's once-daily reference rate
# (qalc-exchange-rates.timer/calc.sh still use the ECB feed via qalc).

token_file="$HOME/.config/wise/token"

rate=$(curl -s --max-time 5 \
  -H "Authorization: Bearer $(cat "$token_file" 2>/dev/null)" \
  "https://api.transferwise.com/v1/rates?source=USD&target=ZAR" \
  2>/dev/null | jq -r '.[0].rate // empty' 2>/dev/null)

if [ -z "$rate" ]; then
  printf '{"text": "USD/ZAR --", "tooltip": "Wise rate lookup failed -- no token, no network, or API error"}\n'
  exit 0
fi

formatted=$(printf '%.2f' "$rate")
printf '{"text": "$1 = R%s", "tooltip": "1 USD = %s ZAR (via Wise)"}\n' "$formatted" "$formatted"

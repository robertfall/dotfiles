#!/usr/bin/env bash
# Single "USD/ZAR · EUR/ZAR" line for hyprlock's info card -- reuses the same
# waybar scripts (and the qalc lookups behind them) rather than duplicating.

usd=$(bash ~/.config/hypr/scripts/usd-zar.sh | jq -r .text)
eur=$(bash ~/.config/hypr/scripts/eur-zar.sh | jq -r .text)

printf '%s · %s\n' "$usd" "$eur"

#!/usr/bin/env bash
# USD->ZAR line chart for waybar's image#usdzar-spark module. Range is
# persisted in usdzar-range and cycled by usd-zar-sparkline-cycle.sh (bound
# to scroll on the module). Output follows waybar-image(5)'s script contract:
# "$path\n$tooltip". Percentage change vs the range's open is written to a
# companion JSON file for custom/usdzar-pct (a real GTK text label) rather
# than baked into the raster, which would shrink to unreadable size along
# with the image once it's scaled down to fit the bar's row height.

cache_dir="$HOME/.cache/waybar-forex"
mkdir -p "$cache_dir"
range_file="$cache_dir/usdzar-range"
data_file="$cache_dir/usdzar.tsv"
png_file="$cache_dir/usdzar.png"
pct_file="$cache_dir/usdzar-pct.json"

range=$(cat "$range_file" 2>/dev/null)
case "$range" in
  month|6month|year) ;;
  *) range="day" ;;
esac

case "$range" in
  day)    ago="24 hours ago"; group="hour"; label="last 24h" ;;
  month)  ago="30 days ago";  group="day";  label="last 30 days" ;;
  6month) ago="182 days ago"; group="day";  label="last 6 months" ;;
  year)   ago="365 days ago"; group="day";  label="last year" ;;
esac

from=$(date -u -d "$ago" +%Y-%m-%dT%H:%M:%S.000Z)
to=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

curl -s --max-time 10 \
  -H "Authorization: Bearer $(cat "$HOME/.config/wise/token" 2>/dev/null)" \
  "https://api.transferwise.com/v1/rates?source=USD&target=ZAR&from=${from}&to=${to}&group=${group}" \
  2>/dev/null | jq -r '[.[] | [.time, .rate]] | reverse | .[] | @tsv' > "$data_file"

if [ ! -s "$data_file" ]; then
  printf '%s\n' "$png_file"
  printf 'USD/ZAR sparkline unavailable -- no data or no network\n'
  printf '{"text": "--", "tooltip": "USD/ZAR sparkline unavailable"}\n' > "$pct_file"
  pkill -RTMIN+10 waybar
  exit 0
fi

open=$(head -1 "$data_file" | cut -f2)
current=$(tail -1 "$data_file" | cut -f2)
pct=$(awk -v o="$open" -v c="$current" 'BEGIN { printf "%+.2f", (c - o) / o * 100 }')

color='#a6e3a1'
awk -v o="$open" -v c="$current" 'BEGIN { exit !(c < o) }' && color='#f38ba8'

gnuplot <<GNUPLOT
set terminal pngcairo transparent size 260,50 font "sans,8"
set output '$png_file'
stats '$data_file' using 2 nooutput
pad = (STATS_max - STATS_min) * 0.15
if (pad == 0) pad = 0.01
set yrange [STATS_min - pad : STATS_max + pad]
unset border
unset xtics
unset ytics
unset key
set lmargin 0
set rmargin 0
set tmargin 0
set bmargin 0
plot $open with lines dashtype 2 lw 1 lc rgb '#6c7086' notitle, \
     '$data_file' using 0:2 with lines lw 2.5 lc rgb '$color' notitle
GNUPLOT

printf "{\"text\": \"<span foreground='%s'>%s%%</span>\", \"tooltip\": \"USD/ZAR %s (%s, open %s)\"}\n" \
  "$color" "$pct" "$current" "$label" "$open" > "$pct_file"
pkill -RTMIN+10 waybar

printf '%s\n' "$png_file"
printf 'USD/ZAR %s (%s, open %s) -- scroll to change range\n' "$current" "$label" "$open"

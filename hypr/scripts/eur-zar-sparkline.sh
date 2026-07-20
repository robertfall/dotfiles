#!/usr/bin/env bash
# EUR->ZAR line chart for waybar's image#eurzar-spark module. Range is
# persisted in eurzar-range and cycled by eur-zar-sparkline-cycle.sh (bound
# to scroll on the module). Output follows waybar-image(5)'s script contract:
# "$path\n$tooltip".

cache_dir="$HOME/.cache/waybar-forex"
mkdir -p "$cache_dir"
range_file="$cache_dir/eurzar-range"
data_file="$cache_dir/eurzar.tsv"
png_file="$cache_dir/eurzar.png"

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
  "https://api.transferwise.com/v1/rates?source=EUR&target=ZAR&from=${from}&to=${to}&group=${group}" \
  2>/dev/null | jq -r '[.[] | [.time, .rate]] | reverse | .[] | @tsv' > "$data_file"

pct_file="$cache_dir/eurzar-pct.json"

if [ ! -s "$data_file" ]; then
  printf '%s\n' "$png_file"
  printf 'EUR/ZAR sparkline unavailable -- no data or no network\n'
  printf '{"text": "--", "tooltip": "EUR/ZAR sparkline unavailable"}\n' > "$pct_file"
  pkill -RTMIN+11 waybar
  exit 0
fi

open=$(head -1 "$data_file" | cut -f2)
current=$(tail -1 "$data_file" | cut -f2)
pct=$(awk -v o="$open" -v c="$current" 'BEGIN { printf "%+.2f", (c - o) / o * 100 }')

# Catppuccin Mocha green/red, matching the palette already used elsewhere in
# style.css (#f38ba8 for workspace.urgent) -- green added here for the first
# time since nothing else in the bar needed an "up" color before this.
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

# Companion GTK text label for custom/eurzar-pct -- real Pango text instead
# of baking the percentage into the raster, since the image gets scaled down
# to fit the bar's row-height budget and any text inside it shrinks along
# with it (unreadable at that scale). custom/eurzar-pct listens on signal 11
# (not 8, the scroll-triggered signal this script itself runs on) and is
# only signalled here, once the file is actually written -- sharing signal 8
# would race the module's near-instant "cat" against this script's ~1-2s
# curl+gnuplot run, showing the previous range's percentage until the next
# trigger.
printf "{\"text\": \"<span foreground='%s'>%s%%</span>\", \"tooltip\": \"EUR/ZAR %s (%s, open %s)\"}\n" \
  "$color" "$pct" "$current" "$label" "$open" > "$pct_file"
pkill -RTMIN+11 waybar

printf '%s\n' "$png_file"
printf 'EUR/ZAR %s (%s, open %s) -- scroll to change range\n' "$current" "$label" "$open"

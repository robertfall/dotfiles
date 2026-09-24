#!/usr/bin/env bash
# Searchable keybind help via fuzzel. Bound to SUPER+SHIFT+/ (Super+?).
# Enter runs the selected bind.
#
# The list comes live from `hyprctl binds`, so it always matches the loaded
# config. The text is each bindd's description (see the KEYBINDINGS section
# of hyprland.conf). A bind without one falls back to "dispatcher arg".
# This parses the plain-text output: `hyprctl binds -j` gives invalid JSON
# on Hyprland 0.56.0 (the fields are shifted by one).

rows=()
dispatchers=()
args=()

mods() {
  local m=$1 out=()
  (( m & 64 )) && out+=(SUPER)
  (( m & 4 ))  && out+=(CTRL)
  (( m & 8 ))  && out+=(ALT)
  (( m & 1 ))  && out+=(SHIFT)
  echo "${out[*]}"
}

keyname() {
  case "$1" in
    mouse:272)  echo "Left drag" ;;
    mouse:273)  echo "Right drag" ;;
    mouse_down) echo "Wheel down" ;;
    mouse_up)   echo "Wheel up" ;;
    Slash)      echo "/" ;;
    grave)      echo "\`" ;;
    XF86*)      echo "${1#XF86}" ;;
    ?)          echo "${1^^}" ;;
    *)          echo "${1^}" ;;
  esac
}

add() {
  # Submap binds (e.g. hyprswitch's own temporary ones) are not global keys.
  [ -n "$submap" ] && return
  local text=$desc
  [ -n "$text" ] || text="$disp $arg"
  local m combo
  m=$(mods "$modmask")
  combo=$(keyname "$key")
  [ -n "$m" ] && combo="$m + $combo"
  rows+=("$(printf '%-52.52s  %s' "$text" "$combo")")
  dispatchers+=("$disp")
  args+=("$arg")
}

while IFS= read -r line; do
  case "$line" in
    bind*)            modmask=0 submap="" key="" desc="" disp="" arg="" ;;
    $'\tmodmask: '*)     modmask=${line#*: } ;;
    $'\tsubmap: '*)      submap=${line#*: } ;;
    $'\tkey: '*)         key=${line#*: } ;;
    $'\tdescription: '*) desc=${line#*: } ;;
    $'\tdispatcher: '*)  disp=${line#*: } ;;
    $'\targ: '*)         arg=${line#*: }; add ;;
  esac
done < <(hyprctl binds)

i=$(printf '%s\n' "${rows[@]}" | fuzzel --dmenu --index --only-match \
  --font='monospace:size=13' --width=80 --lines=20 \
  --prompt='? ' --placeholder='search keybinds') || exit 0
[ -n "$i" ] || exit 0

disp=${dispatchers[$i]}
arg=${args[$i]}

# bindm binds track the pointer while held; there is nothing to run once.
if [ "$disp" = mouse ]; then
  notify-send "Keybinds" "Mouse binds only work with the mouse: hold the keys and drag."
  exit 0
fi

if [ -n "$arg" ]; then
  hyprctl dispatch "$disp" "$arg" >/dev/null
else
  hyprctl dispatch "$disp" >/dev/null
fi

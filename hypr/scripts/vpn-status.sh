#!/usr/bin/env bash
# VPN status for waybar's custom/vpn module -- separate from orbit (which
# only covers wifi/bluetooth). Reports whichever NetworkManager connection of
# type "vpn" is currently active, rather than hardcoding a profile name, so it
# still works if the profile gets renamed or another one is added later.

active=$(nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | awk -F: '$1=="vpn"{print $2; exit}')

# --toggle: bring the active VPN down, or the first known VPN profile up if
# none is active. Kept in this script (rather than inline in waybar's
# on-click) so the "which connection" lookup only lives in one place.
if [ "$1" = "--toggle" ]; then
  if [ -n "$active" ]; then
    nmcli connection down "$active" >/dev/null 2>&1
  else
    profile=$(nmcli -t -f TYPE,NAME connection show 2>/dev/null | awk -F: '$1=="vpn"{print $2; exit}')
    [ -n "$profile" ] && nmcli connection up "$profile" >/dev/null 2>&1
  fi
  exit 0
fi

if [ -n "$active" ]; then
  printf '{"text": "󰦝", "tooltip": "VPN connected: %s"}\n' "$active"
else
  printf '{"text": "󰦞", "tooltip": "VPN disconnected"}\n'
fi

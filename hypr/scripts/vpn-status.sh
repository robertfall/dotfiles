#!/usr/bin/env bash
# VPN status feeding waybar's custom/orbit module -- orbit's own on-click
# (orbit toggle top-right) still opens its wifi/bluetooth/vpn panel, this
# script just decides which icon that module shows. Reports whichever
# NetworkManager connection of type "vpn" is currently active, rather than
# hardcoding a profile name, so it still works if the profile gets renamed
# or another one is added later.

active=$(nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | awk -F: '$1=="vpn"{print $2; exit}')

if [ -n "$active" ]; then
  printf '{"text": "󰦝", "tooltip": "VPN connected: %s"}\n' "$active"
else
  printf '{"text": "󰦞", "tooltip": "VPN disconnected"}\n'
fi

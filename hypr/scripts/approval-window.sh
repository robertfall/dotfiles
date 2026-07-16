#!/usr/bin/env bash
# Chromeless Vivaldi window for the ticketoffice approval dashboard.
# --ozone-platform=x11: Vivaldi's native-Wayland path segfaults on this
# NVIDIA + Hyprland setup; XWayland is the working fallback.
# --class gives it a distinct window so it's just a normal window (no
# special float/workspace rules) apart from having no browser chrome.
exec vivaldi \
    --ozone-platform=x11 \
    --no-first-run \
    --class=vivaldi-approval \
    --app="https://system002.ticketsolve.com/system?subdomain=system002&destination=ticketoffice" \
    --user-data-dir="$HOME/.config/vivaldi-approval-profile"

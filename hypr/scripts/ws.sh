#!/bin/sh

n="$1"
mode="$2"

name=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
case "$name" in
    DP-2)     base=10 ;;
    HDMI-A-1) base=20 ;;
    *)        base=0  ;;
esac

ws=$((base + n))

if [ "$mode" = move ]; then
    hyprctl dispatch "hl.dsp.window.move({ workspace = $ws })"
else
    hyprctl dispatch "hl.dsp.focus({ workspace = $ws })"
fi

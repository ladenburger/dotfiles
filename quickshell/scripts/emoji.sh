#!/usr/bin/env bash

DIR="$(dirname "$(readlink -f "$0")")/.resources"
EMOJIS="$DIR/emojilist"

choice=$(cat "$EMOJIS" | "$HOME/.config/quickshell/scripts/qs-dmenu" "emoji")

[ -z "$choice" ] && exit 0

emoji=$(printf "%s" "$choice" | awk '{print $1}')

wl-copy "$emoji"

notify-send "${emoji} copied to clipboard" -t 3000

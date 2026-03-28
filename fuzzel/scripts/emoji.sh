#!/usr/bin/env bash

DIR="$HOME/.config/fuzzel/scripts/.resources"
EMOJIS="$DIR/emojilist"

# pick emoji
choice=$(cat "$EMOJIS" | fuzzel --dmenu --prompt "emoji ")

# exit if nothing selected
[ -z "$choice" ] && exit 0

# extract the first character (the emoji)
emoji=$(printf "%s" "$choice" | awk '{print $1}')

# copy to clipboard
wl-copy "$emoji"

notify-send "${emoji} copied to clipboard" -t 3000

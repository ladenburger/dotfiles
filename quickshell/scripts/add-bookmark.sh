#!/usr/bin/env bash

bookmark_file=~/files/documents/obsidian-vault/Bookmarks.md
dmenu="$HOME/.config/quickshell/scripts/qs-dmenu"

label=$(: | "$dmenu" "Bookmark name")
[ -z "$label" ] && exit

url=$(: | "$dmenu" "URL")
[ -z "$url" ] && exit

echo "$label:: $url" >> "$bookmark_file"
notify-send "Bookmark added" "$label" -t 2000

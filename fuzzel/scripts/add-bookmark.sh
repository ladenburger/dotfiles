#!/usr/bin/env bash

bookmark_file=~/files/documents/obsidian-vault/Bookmarks.md

label=$(echo "" | fuzzel --dmenu --prompt "Bookmark name: ")
[ -z "$label" ] && exit

url=$(echo "" | fuzzel --dmenu --prompt "URL: ")
[ -z "$url" ] && exit

echo "$label:: $url" >> "$bookmark_file"
notify-send "Bookmark added" "$label" -t 2000

#!/usr/bin/env bash

bookmark_file=~/files/documents/obsidian-vault/Bookmarks.md
browser=/usr/bin/firefox

selected_label=$(cut -d ':' -f1 "$bookmark_file" | fuzzel '--dmenu')

[ -z "$selected_label" ] && exit

selected_url=$(grep "^$selected_label" "$bookmark_file" | cut -d ':' -f3- | xargs)

$browser $selected_url

id=$(niri msg windows | awk '
/Window ID/ { id=$3 }
/App ID: "firefox"/ { print id; exit }
' | tr -d ':')

niri msg action focus-window --id "$id"

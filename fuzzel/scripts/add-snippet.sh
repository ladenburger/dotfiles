#!/usr/bin/env bash

snippet_file=~/files/documents/obsidian-vault/Snippets.md

label=$(echo "" | fuzzel --dmenu --prompt "Snippet name: ")
[ -z "$label" ] && exit

text=$(echo "" | fuzzel --dmenu --prompt "Text: ")
[ -z "$text" ] && exit

echo "$label: $text" >> "$snippet_file"
notify-send "Snippet added" "$label" -t 2000

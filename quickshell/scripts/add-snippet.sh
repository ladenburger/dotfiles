#!/usr/bin/env bash

snippet_file=~/files/documents/obsidian-vault/Snippets.md
dmenu="$HOME/.config/quickshell/scripts/qs-dmenu"

label=$(: | "$dmenu" "Snippet name")
[ -z "$label" ] && exit

text=$(: | "$dmenu" "Text")
[ -z "$text" ] && exit

echo "$label: $text" >> "$snippet_file"
notify-send "Snippet added" "$label" -t 2000

#!/usr/bin/env bash

snippet_file=~/files/documents/obsidian-vault/Snippets.md
dmenu="$HOME/.config/quickshell/scripts/qs-dmenu"

selected=$(sed 's/: / - /' "$snippet_file" | "$dmenu" "snippet")
[ -z "$selected" ] && exit

selected_label=$(echo "$selected" | sed 's/ - .*//')

selected_text=$(grep "^$selected_label:" "$snippet_file" | cut -d ':' -f2- | sed 's/^ //')

sleep 0.2

ydotool type "$selected_text" -d 0 -D 0

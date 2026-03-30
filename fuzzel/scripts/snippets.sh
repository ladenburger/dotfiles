#!/usr/bin/env bash

snippet_file=~/files/documents/obsidian-vault/Snippets.md

# Show "label - preview text" in fuzzel
selected=$(sed 's/: / - /' "$snippet_file" | fuzzel '--dmenu')
[ -z "$selected" ] && exit

# Extract label (everything before first " - ")
selected_label=$(echo "$selected" | sed 's/ - .*//')

selected_text=$(grep "^$selected_label:" "$snippet_file" | cut -d ':' -f2- | sed 's/^ //')

# Brief delay so fuzzel can close and the previous window regains focus
sleep 0.2

ydotool type "$selected_text" -d 0 -D 0

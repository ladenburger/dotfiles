#!/usr/bin/env bash

bookmark_file=~/files/documents/obsidian-vault/Bookmarks.md
browser=/usr/bin/firefox

selected_label=$(cut -d ':' -f1 "$bookmark_file" | fuzzel '--dmenu')
[ -z "$selected_label" ] && exit

selected_url=$(grep "^$selected_label" "$bookmark_file" | cut -d ':' -f3- | xargs)

# Pre-focus an existing Firefox window so the new tab lands there
ff_id=$(niri msg windows | awk '
    /Window ID/ { id=$3 }
    /App ID: "firefox"/ { print id; exit }
' | tr -d ':')
[ -n "$ff_id" ] && niri msg action focus-window --id "$ff_id"

$browser "$selected_url" &

# If Firefox wasn't running, wait for it to appear then grab the new window
if [ -z "$ff_id" ]; then
    sleep 1
    ff_id=$(niri msg windows | awk '
        /Window ID/ { id=$3 }
        /App ID: "firefox"/ { print id; exit }
    ' | tr -d ':')
fi

[ -n "$ff_id" ] && niri msg action focus-window --id "$ff_id"

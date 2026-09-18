#!/usr/bin/env bash

bookmark_file=~/files/documents/obsidian-vault/Bookmarks.md
browser=/usr/bin/firefox
dmenu="$(dirname "$(readlink -f "$0")")/qs-dmenu"

label=$(cut -d ':' -f1 "$bookmark_file" | "$dmenu" "bookmark")
[ -z "$label" ] && exit 0

url=$(grep "^$label" "$bookmark_file" | cut -d ':' -f3- | xargs)
[ -z "$url" ] && exit 1

nohup "$browser" "$url" >/dev/null 2>&1 &
disown

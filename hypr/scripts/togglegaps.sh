#!/bin/sh

state="${XDG_RUNTIME_DIR:-/tmp}/hypr-gaps"

off_border="rgba(504945ff)"

get() { hyprctl getoption -j "$1" | jq -r '.css // .int // .gradient'; }

tbl() {
    set -- $1
    printf '{ top = %s, right = %s, bottom = %s, left = %s }' "$1" "$2" "$3" "$4"
}

rgba() {
    c=${1%% *}
    case $c in *[!0-9a-fA-F]*) return 1 ;; esac
    [ ${#c} -eq 8 ] || return 1
    printf 'rgba(%s%s)' "$(printf %s "$c" | cut -c3-8)" "$(printf %s "$c" | cut -c1-2)"
}

apply() {
    hyprctl eval "hl.config({
        general = {
            gaps_in  = $(tbl "$1"),
            gaps_out = $(tbl "$2"),
            col = { active_border = \"$4\" },
        },
        decoration = { rounding = $3 },
    })" >/dev/null
}

if [ "$(get general:gaps_out)" = "0 0 0 0" ]; then
    if { read -r gaps_in && read -r gaps_out && read -r rounding && read -r border; } 2>/dev/null < "$state" &&
       [ -n "$gaps_in" ] && [ -n "$gaps_out" ] && [ -n "$rounding" ] && [ -n "$border" ]; then
        apply "$gaps_in" "$gaps_out" "$rounding" "$border"
    else
        hyprctl reload >/dev/null
    fi
    rm -f "$state"
else
    if border=$(rgba "$(get general:col.active_border)"); then
        printf '%s\n%s\n%s\n%s\n' \
            "$(get general:gaps_in)" "$(get general:gaps_out)" \
            "$(get decoration:rounding)" "$border" > "$state"
    else
        rm -f "$state"
    fi
    apply "0 0 0 0" "0 0 0 0" 0 "$off_border"
fi

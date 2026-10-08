#!/bin/sh

# tty1 autologins and .zprofile starts Hyprland again; the marker tells it to
# leave this one login at a shell. /tmp so a stale marker can't outlive a boot.
touch "/tmp/hypr-logout-$(id -u)"

command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown
hyprctl dispatch 'hl.dsp.exit()'

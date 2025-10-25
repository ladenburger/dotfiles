#!/usr/bin/env bash

alacritty_cfg="$HOME/.config/alacritty/alacritty.toml"
waybar_cfg="$HOME/.config/waybar/style.css"

ALACRITTY_OPAQUE=1.0
ALACRITTY_TRANSPARENT=0.92

WAYBAR_OPAQUE="rgba(17, 17, 17, 1.00)"
WAYBAR_TRANSPARENT="rgba(17, 17, 17, 0.91)"

# ------------------- Alacritty -------------------
if grep -q "opacity *= *$ALACRITTY_TRANSPARENT" "$alacritty_cfg"; then
    sed -i "s/opacity *= *$ALACRITTY_TRANSPARENT/opacity = $ALACRITTY_OPAQUE/" "$alacritty_cfg"
    alacritty_state="opaque"
else
    if grep -q "opacity" "$alacritty_cfg"; then
        sed -i "s/opacity *= *[0-9.]\+/opacity = $ALACRITTY_TRANSPARENT/" "$alacritty_cfg"
    else
        awk -v val="$ALACRITTY_TRANSPARENT" '
            /^\[window\]/ { print; print "opacity = " val; next }1
        ' "$alacritty_cfg" > "${alacritty_cfg}.tmp" && mv "${alacritty_cfg}.tmp" "$alacritty_cfg"
    fi
    alacritty_state="transparent"
fi

# ------------------- Waybar -------------------
if grep -q "$WAYBAR_TRANSPARENT" "$waybar_cfg"; then
    sed -i "s|$WAYBAR_TRANSPARENT|$WAYBAR_OPAQUE|" "$waybar_cfg"
    waybar_state="opaque"
else
    sed -i "s|$WAYBAR_OPAQUE|$WAYBAR_TRANSPARENT|" "$waybar_cfg"
    waybar_state="transparent"
fi

# --- Restart Waybar ---
echo "Restartinging waybar"
pkill waybar && nohup waybar >/dev/null 2>&1 &

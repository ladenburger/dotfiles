# Auto-start Hyprland on tty1
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == "1" && "$ACTIVE_WM" == "niri" ]]; then

    if [[ "$ACTIVE_WM" == "niri" ]]; then
    exec ~/.local/bin/start-niri
    fi

    if [[ "$ACTIVE_WM" == "hyprland" ]]; then
    exec start-hyprland
    fi

fi


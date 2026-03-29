#!/bin/sh

# zsh + plugins
sudo pacman -S zsh zsh-syntax-highlighting zsh-autosuggestions

# don't create .zshrc in $HOME
echo "export ZDOTDIR=\"\$HOME\"/.config/zsh" >> /etc/zsh/zshenv

CFG="$HOME/.config"

# Distro icon for waybar
if grep -qi "gentoo" /etc/os-release 2>/dev/null; then
    cp "$CFG/waybar/distro-gentoo" "$CFG/waybar/distro"
elif grep -qi "artix" /etc/os-release 2>/dev/null; then
    cp "$CFG/waybar/distro-artix" "$CFG/waybar/distro"
else
    # fallback: generic linux icon
    printf "󰌽" > "$CFG/waybar/distro"
fi

# Initialize theme (generates all config files that switch-theme manages)
# Defaults to gruvbox — pass a theme name as argument to override: ./init.sh rosepine
THEME="${1:-gruvbox}"
switch-theme "$THEME"

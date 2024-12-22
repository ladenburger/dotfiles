#!/bin/sh

# zsh + plugins
sudo pacman -S zsh zsh-syntax-highlighting zsh-autosuggestions

# don't create .zshrc in $HOME
echo "export ZDOTDIR=\"\$HOME\"/.config/zsh" >> /etc/zsh/zshenv


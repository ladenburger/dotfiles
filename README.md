# Welcome
These are my current dotfiles. You may find some of it useful.
I'm currently using [Hyprland](https://github.com/hyprwm/Hyprland).

**Feel free to use and share.**
# Current Tools and Configs
- **WM**: [Hyprland](https://github.com/hyprwm/Hyprland)
- **Terminal**: [Ghostty](https://github.com/ghostty-org) & [Alacritty](https://alacritty.org/)
- **Terminal multiplexer**: [tmux](https://github.com/tmux/tmux)
- **Shell**: [zsh](https://github.com/zsh-users/zsh)
- **Prompt**: [Starship](https://starship.rs/)
- **Editor**: [NeoVim](https://github.com/neovim/neovim)
- **Application launcher**: [Wofi](https://github.com/SimplyCEO/wofi)
- **Statusbar**: [Waybar](https://github.com/Alexays/Waybar)
- **Notifications**: [Dunst](https://github.com/dunst-project/dunst)
  
# Preview
## Prompt
![prompt](https://github.com/user-attachments/assets/a27f6968-959e-4a81-b796-31ab5c1240ab)
## Waybar
![prompt](https://github.com/user-attachments/assets/2249c82f-1bae-417c-8dd9-2e3888ff9914)
## Nvim
![nvim](https://github.com/user-attachments/assets/28eacd68-13db-431a-9a98-df31934e327a)

# Useful stuff 
## Hyprcursor used
[RosePine Hyprcursor](https://github.com/ndom91/rose-pine-hyprcursor)

## Fixing PTT on Wayland (for now :))
[ptt-fix](https://github.com/DeedleFake/ptt-fix) (config in repo)

## Themes
- **GTK (Gruvbox)**: [Fausto-Korpsvart/Gruvbox-GTK-Theme](https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme) → `~/.local/share/themes/`
- **GTK (Rosé Pine)**: [rose-pine/gtk](https://github.com/rose-pine/gtk) → `~/.local/share/themes/`

### Window Manager
The `ACTIVE_WM` environment variable controls which window manager is autostarted. Set it in your shell profile (e.g. `~/.zprofile`):
```sh
export ACTIVE_WM=hyprland  # or niri, etc.
```

### switch-theme
The `switch-theme` script switches between gruvbox and rosepine. Symlink it to `~/.local/bin`:
```sh
ln -s /path/to/dotfiles/switch-theme ~/.local/bin/switch-theme
```

## Icons
- **Gruvbox Dark**: [jmattheis/gruvbox-dark-icons-gtk](https://github.com/jmattheis/gruvbox-dark-icons-gtk) → `~/.local/share/icons/`
- **Rosé Pine**: [rose-pine/gtk](https://github.com/rose-pine/gtk) (icons release) → `~/.local/share/icons/`

## Fonts
- **ZedMono**: [zed-industries/zed-fonts](https://github.com/zed-industries/zed-fonts) → `~/.local/share/fonts/`

## Cursor
- **Bibata Modern Ice**: [ful1e5/Bibata_Cursor](https://github.com/ful1e5/Bibata_Cursor)

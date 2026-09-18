# dotfiles

Gentoo / [Hyprland](https://github.com/hyprwm/Hyprland) (Lua config) with a
[Quickshell](https://quickshell.outfoxxed.me/) bar, notifications and launcher.
Feel free to use and share.

| | |
|---|---|
| WM | Hyprland — `hypr/` |
| Bar, notifications, launcher | Quickshell — `quickshell/` |
| Terminal | Ghostty, Alacritty — `alacritty/` |
| Multiplexer | tmux — `tmux/` |
| Shell, prompt | zsh, Starship — `zsh/`, `starship/` |
| Editor | Neovim — `nvim/` |
| Input method | fcitx5 + mozc — `fcitx5/` |
| Feeds | newsboat — `newsboat/` |
| System info | fastfetch, btop — `fastfetch/`, `btop/` |
| Push-to-talk | [ptt-fix](https://github.com/DeedleFake/ptt-fix) — `ptt-fix/` |
| Sentence mining | SubMiner + Anki — `SubMiner/` |
| Toolkits | `gtk-2.0/`, `gtk-3.0/`, `xfce4/`, `ts3/` |

## Install

Every directory is symlinked into `~/.config`:

```sh
ln -s ~/files/repos/dotfiles/hypr ~/.config/hypr
```

zsh needs `ZDOTDIR` set before it reads anything:

```sh
echo 'export ZDOTDIR="$HOME"/.config/zsh/' | sudo tee -a /etc/zsh/zshenv
```

XDG base dirs, `PATH` and the per-tool env vars that keep programs out of
`$HOME` live in `zsh/.zshrc`. User directories are in `user-dirs.dirs` —
everything under `~/files` except downloads; screenshots go to
`~/files/pictures/screenshots`, passed to hyprshot explicitly by `SUPER+P`.

## Assets

- GTK: [Gruvbox-GTK-Theme](https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme) → `~/.local/share/themes/`
- Icons: [gruvbox-dark-icons-gtk](https://github.com/jmattheis/gruvbox-dark-icons-gtk) → `~/.local/share/icons/`
- Fonts: [ZedMono](https://github.com/zed-industries/zed-fonts) → `~/.local/share/fonts/`
- Cursor: [Bibata Modern Ice](https://github.com/ful1e5/Bibata_Cursor)

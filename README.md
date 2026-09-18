# dotfiles

Gentoo / [Hyprland](https://github.com/hyprwm/Hyprland) (Lua config) with a
[Quickshell](https://quickshell.outfoxxed.me/) bar, notifications and launcher.
Feel free to use and share.

| | |
|---|---|
| WM | Hyprland — `hypr/hyprland.lua` |
| Bar / notifications / launcher | Quickshell — `quickshell/` |
| Terminal | Ghostty, Alacritty |
| Multiplexer | tmux |
| Shell / prompt | zsh, Starship |
| Editor | Neovim |
| Input | fcitx5 + mozc — `fcitx5/` |
| PTT on Wayland | [ptt-fix](https://github.com/DeedleFake/ptt-fix) — `ptt-fix/config` |

![prev1](https://github.com/user-attachments/assets/324d6cbb-937d-4f63-a25d-0f7bfcd9af50)
![prev2](https://github.com/user-attachments/assets/cecd6b47-06d0-4acf-9d5c-22c5bbf19992)

## Keyboard

`ALT+SHIFT` cycles one fcitx5 group: `keyboard-us`, `keyboard-de`, `mozc`.
Hyprland's xkb layout follows the selected engine, and the bar's pill
(`quickshell/modules/Ime.qml`) clicks, scrolls and right-clicks through the
same list.

| what | gets its layout from |
|---|---|
| text-input-v3 clients | fcitx5's active engine |
| everything else, XWayland included | Hyprland's xkb group |

## Setup

```sh
echo 'app-i18n/fcitx wayland X'     | sudo tee    /etc/portage/package.use/fcitx5
echo 'app-i18n/fcitx-qt wayland X'  | sudo tee -a /etc/portage/package.use/fcitx5
echo 'app-i18n/fcitx-gtk wayland X' | sudo tee -a /etc/portage/package.use/fcitx5
echo 'app-i18n/mozc fcitx5 -ibus'   | sudo tee -a /etc/portage/package.use/fcitx5
echo 'export ZDOTDIR="$HOME"/.config/zsh/' | sudo tee -a /etc/zsh/zshenv
```

Configs are symlinked into `~/.config`. Screenshots go to
`~/files/pictures/screenshots`, passed to hyprshot explicitly by `SUPER+P`.

## Assets

- GTK: [Gruvbox-GTK-Theme](https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme) → `~/.local/share/themes/`
- Icons: [gruvbox-dark-icons-gtk](https://github.com/jmattheis/gruvbox-dark-icons-gtk) → `~/.local/share/icons/`
- Fonts: [ZedMono](https://github.com/zed-industries/zed-fonts) → `~/.local/share/fonts/`
- Cursor: [Bibata Modern Ice](https://github.com/ful1e5/Bibata_Cursor)

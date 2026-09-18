# fcitx5

English (US), German and Japanese as three entries in one fcitx5 group, cycled
with `ALT+SHIFT` — bound in `hypr/hyprland.lua` to `quickshell:imcycle`.
Hyprland's xkb layout follows the selected engine, so XWayland types the same
as everything else. The bar's pill switches and shows it
(`quickshell/modules/Ime.qml`).

Gentoo:

```sh
echo 'app-i18n/fcitx wayland X'     | sudo tee    /etc/portage/package.use/fcitx5
echo 'app-i18n/fcitx-qt wayland X'  | sudo tee -a /etc/portage/package.use/fcitx5
echo 'app-i18n/fcitx-gtk wayland X' | sudo tee -a /etc/portage/package.use/fcitx5
echo 'app-i18n/mozc fcitx5 -ibus'   | sudo tee -a /etc/portage/package.use/fcitx5
```

`hypr/hyprland.lua` starts `fcitx5 -d -r` and exports `XMODIFIERS`,
`QT_IM_MODULE` and `SDL_IM_MODULE`; `GTK_IM_MODULE` is left unset so GTK keeps
using its own Wayland text-input.

`config` holds only what differs from fcitx5's defaults — the emptied switch
keys, the shared input state, and the tray addon turned off.

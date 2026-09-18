# quickshell

Bar, notifications, launcher and desktop widgets. Replaces waybar, mako/swaync
and fuzzel. Started by `hypr/hyprland.lua` as `env QT_IM_MODULE=none qs`;
`shell.qml` instantiates the per-monitor and singleton windows.

| | |
|---|---|
| bar | `Bar` `BarMenu` `Pill` `Workspaces` `ActiveWindow` `Clock` `Battery` `Volume` `Sys` `SysPill` `Gauge` `Tray` `TrayMenu` `TrayMenuLevel` `DistroLogo` |
| input method | `Ime` `InputState` `LangMenu` `LangState` |
| menus / overlays | `Launcher` `AltTab` `PowerMenu` `NetworkMenu` `BluetoothMenu` `CalendarPopup` `MenuPanel` `ClickAway` `VolumeOsd` `MathView` `math.js` |
| notifications | `Notifications` `NotifPopups` `NotifCenter` `NotifCard` `NotifBell` |
| desktop | `DesktopClock` `DesktopMedia` `DesktopVisualizer` `DesktopWall` `Cava` `ScreenCorners` `CornerWedge` |
| shared | `Theme` `Hypr` |

Scripts in `scripts/` back the launcher's modes (`qs-dmenu`, bookmarks,
snippets, emoji) and the desktop clock's wallpaper cutout.

IPC: `qs ipc call im next|prev|select <name>|status`.

## Notes

- The shell runs with `QT_IM_MODULE=none`. With the session's `fcitx` value its
  overlays get an input context of their own, which reads as a switch to
  English whenever one takes the keyboard.
- fcitx5 attaches `hl-virtual-keyboard-fcitx5` to the seat when a text-input
  client is focused, and it is always `English (US)`. `InputState` ignores
  layout events from virtual keyboards; taking them at face value switched the
  session to US on every focus change.

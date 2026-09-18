pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var fullscreenMonitors: {
        const mons = Hyprland.monitors ? Hyprland.monitors.values : [];
        const tls = Hyprland.toplevels ? Hyprland.toplevels.values : [];

        const showing = ({});
        for (const m of mons) {
            const o = m.lastIpcObject;
            if (o && o.activeWorkspace)
                showing[o.activeWorkspace.id] = m.name;
        }

        const out = [];
        for (const t of tls) {
            const o = t.lastIpcObject;
            if (!o || o.fullscreen !== 2 || !o.workspace) continue;
            const name = showing[o.workspace.id];
            if (name && out.indexOf(name) < 0) out.push(name);
        }
        return out;
    }

    function fullscreenOn(name) {
        return name !== undefined && name.length > 0 && root.fullscreenMonitors.indexOf(name) >= 0;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            switch (event.name) {
            case "fullscreen":
            case "openwindow":
            case "closewindow":
            case "movewindow":
            case "movewindowv2":
                Hyprland.refreshToplevels();
                break;
            case "workspace":
            case "workspacev2":
            case "focusedmon":
            case "focusedmonv2":
                Hyprland.refreshMonitors();
                Hyprland.refreshToplevels();
                break;
            }
        }
    }
}

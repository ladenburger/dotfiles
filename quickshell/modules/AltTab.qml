import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property Theme theme: Theme {}

    property bool shown: false
    property var entries: []
    property int selectedIndex: 0

    readonly property var selected: win.entries[win.selectedIndex] ?? null

    function rebuild() {
        const tls = Hyprland.toplevels ? Hyprland.toplevels.values.slice() : [];
        const wsid = t => t.workspace ? t.workspace.id : 99999;
        const at = t => (t.lastIpcObject && t.lastIpcObject.at) ? t.lastIpcObject.at : [0, 0];
        tls.sort((a, b) => {
            if (wsid(a) !== wsid(b)) return wsid(a) - wsid(b);
            const rowA = Math.round(at(a)[1] / 40);
            const rowB = Math.round(at(b)[1] / 40);
            if (rowA !== rowB) return rowA - rowB;
            return at(a)[0] - at(b)[0];
        });
        win.entries = tls;
    }

    function step(dir) {
        if (!win.shown) {
            Hyprland.refreshToplevels();
            win.rebuild();
            const n = win.entries.length;
            if (n === 0) return;

            let cur = win.entries.findIndex(e => e.activated);
            if (cur < 0) cur = win.entries.findIndex(e => e.lastIpcObject && e.lastIpcObject.focusHistoryID === 0);
            if (cur < 0) cur = dir > 0 ? -1 : 0;
            win.selectedIndex = ((cur + dir) % n + n) % n;
            win.shown = true;
        } else {
            const n = win.entries.length;
            if (n === 0) { win.shown = false; return; }
            win.selectedIndex = ((win.selectedIndex + dir) % n + n) % n;
        }
    }

    function confirm() {
        const e = win.selected;
        win.shown = false;
        if (!e || !e.address) return;

        const addr = e.address.startsWith("0x") ? e.address : "0x" + e.address;
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ window = "address:${addr}" })`]);
    }

    function cancel() { win.shown = false }

    readonly property var wsList: {
        const seen = ({});
        const list = [];
        for (const e of win.entries) {
            const ws = e.workspace;
            if (!ws || ws.id in seen) continue;
            seen[ws.id] = true;
            list.push(ws);
        }
        list.sort((a, b) => a.id - b.id);
        return list;
    }

    screen: {
        const fm = Hyprland.focusedMonitor;
        if (fm) {
            const m = Quickshell.screens.find(s => s.name === fm.name);
            if (m) return m;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-alttab"
    WlrLayershell.keyboardFocus: win.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: win.shown || closeHold.running

    Timer { id: closeHold; interval: win.theme.durMed + 60 }
    onShownChanged: if (!shown) closeHold.restart()

    GlobalShortcut {
        name: "alttab"
        description: "Window switcher – next"
        onPressed: win.step(1)
    }
    GlobalShortcut {
        name: "alttabPrev"
        description: "Window switcher – previous"
        onPressed: win.step(-1)
    }

    GlobalShortcut {
        name: "alttabConfirm"
        description: "Window switcher – accept selection"
        onPressed: if (win.shown) win.confirm()
    }

    IpcHandler {
        target: "alttab"
        function next(): void { win.step(1) }
        function prev(): void { win.step(-1) }
        function accept(): void { win.confirm() }
        function dismiss(): void { win.cancel() }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.106, 0.106, 0.106, 0.94)
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: win.theme.durMed } }
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                win.cancel(); event.accepted = true;
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {

                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                win.confirm(); event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                win.step(-1); event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                win.step(1); event.accepted = true;
            }
        }
        Keys.onReleased: event => {
            if (event.isAutoRepeat) return;
            if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R
                    || event.key === Qt.Key_Meta || event.key === Qt.Key_Alt) {
                win.confirm(); event.accepted = true;
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 26
            opacity: win.shown ? 1 : 0
            scale: win.shown ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: win.theme.durMed } }
            Behavior on scale { NumberAnimation { duration: win.theme.durMed; easing.type: Easing.OutBack; easing.overshoot: win.theme.overshoot } }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Repeater {
                    model: win.wsList

                    delegate: Column {
                        id: wsCol
                        required property var modelData
                        readonly property var mon: modelData.monitor
                        readonly property real aspect: wsCol.mon && wsCol.mon.height > 0 ? wsCol.mon.width / wsCol.mon.height : 16 / 9
                        readonly property int cardW: {
                            const avail = (win.screen ? win.screen.width : 1920) - 160;
                            const n = Math.max(1, win.wsList.length);
                            return Math.max(150, Math.min(320, Math.floor(avail / n) - 20));
                        }
                        readonly property int cardH: Math.round(cardW / wsCol.aspect)
                        readonly property real sc: wsCol.cardW / (wsCol.mon && wsCol.mon.width > 0 ? wsCol.mon.width : 1920)
                        readonly property var wins: win.entries.filter(e => e.workspace && e.workspace.id === wsCol.modelData.id)

                        spacing: 8

                        Row {
                            spacing: 6
                            Text {
                                text: wsCol.modelData.id < 0 ? "\u{f0cd7}" : "\u{f0578}"
                                color: wsCol.modelData.focused ? win.theme.highlight : win.theme.muted
                                font.family: win.theme.fontFamily
                                font.pixelSize: 12
                            }
                            Text {
                                text: wsCol.modelData.id < 0 ? "special" : ("Workspace " + wsCol.modelData.id)
                                color: wsCol.modelData.focused ? win.theme.highlight : win.theme.subtext
                                font.family: win.theme.fontFamily
                                font.pixelSize: 12
                                font.bold: wsCol.modelData.focused
                            }
                        }

                        Rectangle {
                            width: wsCol.cardW
                            height: wsCol.cardH
                            radius: win.theme.radius
                            antialiasing: true
                            color: Qt.rgba(win.theme.bg.r, win.theme.bg.g, win.theme.bg.b, 1)
                            border.width: 1
                            border.color: wsCol.modelData.focused ? win.theme.highlight : win.theme.borderDim
                            clip: true

                            Repeater {
                                model: wsCol.wins

                                delegate: Rectangle {
                                    id: tile
                                    required property var modelData
                                    readonly property var ipc: modelData.lastIpcObject ?? ({})
                                    readonly property bool current: modelData === win.selected

                                    x: Math.max(1, ((tile.ipc.at ? tile.ipc.at[0] : 0) - (wsCol.mon ? wsCol.mon.x : 0)) * wsCol.sc)
                                    y: Math.max(1, ((tile.ipc.at ? tile.ipc.at[1] : 0) - (wsCol.mon ? wsCol.mon.y : 0)) * wsCol.sc)
                                    width: Math.max(28, (tile.ipc.size ? tile.ipc.size[0] : 200) * wsCol.sc - 2)
                                    height: Math.max(22, (tile.ipc.size ? tile.ipc.size[1] : 150) * wsCol.sc - 2)

                                    radius: win.theme.radiusSmall
                                    color: tile.current ? win.theme.highlight : win.theme.pill
                                    border.width: tile.current ? 2 : 1
                                    border.color: tile.current ? win.theme.highlight : win.theme.border
                                    z: tile.current ? 10 : 0
                                    antialiasing: true

                                    Behavior on color { ColorAnimation { duration: win.theme.durFast } }
                                    scale: tile.current ? 1.04 : 1
                                    Behavior on scale { NumberAnimation { duration: win.theme.durFast; easing.type: Easing.OutCubic } }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        width: parent.width - 8

                                        Image {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 22
                                            height: 22
                                            visible: tile.height > 40 && source.toString().length > 0
                                            source: {
                                                const c = String(tile.ipc["class"] || "");
                                                return Quickshell.iconPath(c, true)
                                                    || Quickshell.iconPath(c.toLowerCase(), true)
                                                    || Quickshell.iconPath(c.toLowerCase().replace(/\s+/g, "-"), "");
                                            }
                                            sourceSize.width: 44
                                            sourceSize.height: 44
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            visible: tile.height > 26
                                            text: tile.ipc["class"] || tile.modelData.title || "?"
                                            color: tile.current ? win.theme.solidBg : win.theme.text
                                            font.family: win.theme.fontFamily
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.selected ? (win.selected.lastIpcObject && win.selected.lastIpcObject["class"] ? win.selected.lastIpcObject["class"] : "") : ""
                    color: win.theme.highlight
                    font.family: win.theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.selected ? win.selected.title : ""
                    color: win.theme.subtext
                    font.family: win.theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 720)
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

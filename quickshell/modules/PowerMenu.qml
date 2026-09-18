import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property Theme theme: Theme {}

    readonly property var actions: [
        { key: "l", glyph: "\u{f033e}", label: "Lock",      cmd: ["loginctl", "lock-session"] },
        { key: "e", glyph: "\u{f0343}", label: "Logout",    cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
        { key: "u", glyph: "\u{f04b2}", label: "Suspend",   cmd: ["systemctl", "suspend"] },
        { key: "h", glyph: "\u{f0717}", label: "Hibernate", cmd: ["systemctl", "hibernate"] },
        { key: "r", glyph: "\u{f0709}", label: "Reboot",    cmd: ["systemctl", "reboot"] },
        { key: "s", glyph: "\u{f0425}", label: "Shutdown",  cmd: ["systemctl", "poweroff"] }
    ]

    property bool shown: false
    property int focusedIndex: 0

    function toggle() { win.shown ? win.hide() : win.show() }
    function show() {
        win.focusedIndex = 0;
        win.shown = true;
    }
    function hide() { win.shown = false }
    function run(i) {
        const a = win.actions[i];
        if (!a) return;
        win.shown = false;
        Quickshell.execDetached(a.cmd);
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
    WlrLayershell.namespace: "quickshell-powermenu"
    WlrLayershell.keyboardFocus: win.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: win.shown || closeHold.running

    Timer { id: closeHold; interval: win.theme.durSlow + 60 }
    onShownChanged: if (!shown) closeHold.restart()

    IpcHandler {
        target: "powermenu"
        function toggle(): void { win.toggle() }
        function show(): void { win.show() }
        function hide(): void { win.hide() }
    }

    GlobalShortcut {
        name: "powermenu"
        description: "Toggle the power / logout screen"
        onPressed: win.toggle()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.106, 0.106, 0.106, 0.97)
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: win.theme.durMed } }

        MouseArea {
            anchors.fill: parent
            onClicked: win.hide()
        }
    }

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                win.hide(); event.accepted = true; break;
            case Qt.Key_Left:
            case Qt.Key_H:
                win.focusedIndex = (win.focusedIndex + win.actions.length - 1) % win.actions.length;
                event.accepted = true; break;
            case Qt.Key_Right:
            case Qt.Key_L:
                win.focusedIndex = (win.focusedIndex + 1) % win.actions.length;
                event.accepted = true; break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                win.run(win.focusedIndex); event.accepted = true; break;
            default: {
                const t = event.text.toLowerCase();
                for (let i = 0; i < win.actions.length; i++) {
                    if (win.actions[i].key === t) {
                        win.focusedIndex = i;
                        win.run(i);
                        event.accepted = true;
                        return;
                    }
                }
            }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 34
            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: win.theme.durMed } }
            scale: win.shown ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: win.theme.durMed; easing.type: Easing.OutBack; easing.overshoot: win.theme.overshoot } }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22

                Repeater {
                    model: win.actions

                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index

                        readonly property bool current: win.focusedIndex === tile.index

                        width: 150
                        height: 150
                        radius: win.theme.radius
                        color: tile.current ? win.theme.highlight : win.theme.solidBg
                        border.width: 1
                        border.color: tile.current ? win.theme.highlight : win.theme.border
                        antialiasing: true

                        Behavior on color { ColorAnimation { duration: win.theme.durFast } }
                        scale: tile.current ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: win.theme.durFast; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 12

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.glyph
                                color: tile.current ? win.theme.solidBg : win.theme.text
                                font.family: win.theme.fontFamily
                                font.pixelSize: 46
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.label
                                color: tile.current ? win.theme.solidBg : win.theme.subtext
                                font.family: win.theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        Text {
                            anchors { top: parent.top; left: parent.left; margins: 8 }
                            text: tile.modelData.key
                            color: tile.current ? win.theme.solidBg : win.theme.muted
                            font.family: win.theme.fontFamily
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.focusedIndex = tile.index
                            onClicked: win.run(tile.index)
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Esc to cancel"
                color: win.theme.muted
                font.family: win.theme.fontFamily
                font.pixelSize: 12
            }
        }
    }
}

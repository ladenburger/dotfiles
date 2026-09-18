import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property Theme theme
    required property var screen
    property string specialName: "magic"

    readonly property int cell: 24
    readonly property int gap: 6

    readonly property var hlMonitor: {
        const mons = Hyprland.monitors ? Hyprland.monitors.values : [];
        return mons.find(m => m.name === (root.screen ? root.screen.name : "")) ?? null;
    }

    property string activeSpecial: ""
    readonly property bool specialShown: activeSpecial.length > 0
    readonly property string specialShort: {
        const n = root.activeSpecial;
        const c = n.indexOf(":") >= 0 ? n.slice(n.indexOf(":") + 1) : n;
        return c.length > 0 ? c : "special";
    }

    function seedSpecial() {
        const ipc = root.hlMonitor && root.hlMonitor.lastIpcObject
            ? root.hlMonitor.lastIpcObject.specialWorkspace : null;
        root.activeSpecial = ipc && ipc.name ? ipc.name : "";
    }
    Component.onCompleted: seedSpecial()
    onHlMonitorChanged: seedSpecial()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activespecial" && event.name !== "activespecialv2") return;
            const parts = event.data.split(",");
            const mon = parts[parts.length - 1];
            if (mon !== (root.screen ? root.screen.name : "")) return;
            root.activeSpecial = parts.length >= 2 ? parts[parts.length - 2] : "";
        }
    }

    readonly property var monitorWorkspaces: {
        const list = Hyprland.workspaces ? Hyprland.workspaces.values.slice() : [];
        return list
            .filter(w => w.id > 0 && w.monitor && root.screen && w.monitor.name === root.screen.name)
            .sort((a, b) => a.id - b.id);
    }

    readonly property int focusedIndex: {
        for (let i = 0; i < monitorWorkspaces.length; i++)
            if (monitorWorkspaces[i].focused) return i;
        return -1;
    }

    function cycle(dir) {
        const ws = root.monitorWorkspaces;
        if (root.focusedIndex < 0 || ws.length === 0) return;
        const next = (root.focusedIndex + dir + ws.length) % ws.length;
        ws[next].activate();
    }

    function toggleSpecial() {
        Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.workspace.toggle_special("${root.specialName}")`]);
    }

    implicitWidth: outer.implicitWidth
    implicitHeight: cell
    Behavior on implicitWidth { NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutCubic } }

    Row {
        id: outer
        spacing: root.gap

        Rectangle {
            id: wand
            width: root.cell
            height: root.cell
            radius: root.theme.radiusSmall
            antialiasing: true
            color: root.specialShown
                ? root.theme.highlight
                : (wandMouse.containsMouse ? root.theme.pillHover : root.theme.pill)
            Behavior on color { ColorAnimation { duration: root.theme.durFast } }

            scale: wandMouse.pressed ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: root.theme.durFast; easing.type: Easing.OutBack; easing.overshoot: root.theme.overshoot } }

            Text {
                anchors.centerIn: parent
                text: "\u{f0068}"
                color: root.specialShown ? root.theme.solidBg : root.theme.subtext
                font.family: root.theme.fontFamily
                font.pixelSize: 13
                Behavior on color { ColorAnimation { duration: root.theme.durMed } }
            }

            MouseArea {
                id: wandMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleSpecial()
            }
        }

        Item {
            id: numbered
            height: root.cell
            width: root.specialShown ? 0 : numbersRow.implicitWidth
            opacity: root.specialShown ? 0 : 1
            clip: true
            Behavior on width { NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: root.theme.durFast } }

            Rectangle {
                visible: root.focusedIndex >= 0
                width: root.cell
                height: root.cell
                radius: root.theme.radiusSmall
                antialiasing: true
                color: root.theme.highlight
                x: root.focusedIndex * (root.cell + root.gap)
                Behavior on x {
                    NumberAnimation { duration: root.theme.durMed; easing.type: root.theme.easeStandard }
                }
            }

            Row {
                id: numbersRow
                spacing: root.gap

                Repeater {
                    model: root.monitorWorkspaces

                    delegate: Rectangle {
                        id: wsDelegate
                        required property var modelData
                        required property int index

                        width: root.cell
                        height: root.cell
                        radius: root.theme.radiusSmall
                        antialiasing: true
                        color: modelData.focused
                            ? "transparent"
                            : (wsMouse.containsMouse ? root.theme.pillHover : root.theme.pill)
                        border.width: modelData.urgent ? 2 : 0
                        border.color: root.theme.critical

                        Behavior on color { ColorAnimation { duration: root.theme.durFast } }

                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale {
                            NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutBack; easing.overshoot: root.theme.overshoot }
                        }

                        SequentialAnimation {
                            running: wsDelegate.modelData.urgent
                            loops: Animation.Infinite
                            NumberAnimation { target: wsDelegate; property: "opacity"; to: 0.55; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { target: wsDelegate; property: "opacity"; to: 1; duration: 500; easing.type: Easing.InOutSine }
                        }

                        Text {
                            anchors.centerIn: parent

                            text: ((wsDelegate.modelData.id - 1) % 10) + 1
                            color: wsDelegate.modelData.focused ? root.theme.solidBg : root.theme.text
                            font.family: root.theme.fontFamily
                            font.pixelSize: 12
                            font.bold: wsDelegate.modelData.focused
                            Behavior on color { ColorAnimation { duration: root.theme.durMed } }
                        }

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wsDelegate.modelData.activate()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: specialPill
            height: root.cell
            radius: root.theme.radiusSmall
            antialiasing: true
            width: root.specialShown ? specialLabel.implicitWidth + 20 : 0
            opacity: root.specialShown ? 1 : 0
            clip: true
            color: root.theme.pill
            Behavior on width { NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: root.theme.durFast } }

            Text {
                id: specialLabel
                anchors.centerIn: parent
                text: root.specialShort
                color: root.theme.highlight
                font.family: root.theme.fontFamily
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.cycle(event.angleDelta.y > 0 ? -1 : 1)
    }
}

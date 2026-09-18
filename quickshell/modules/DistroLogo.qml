import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    required property Theme theme

    implicitWidth: 40
    implicitHeight: theme.pillHeight
    radius: theme.radiusSmall
    color: mouse.containsMouse ? theme.pillHover : theme.pill
    antialiasing: true

    Behavior on color { ColorAnimation { duration: theme.durFast } }

    Text {
        id: glyph
        anchors.centerIn: parent
        text: "\u{f08e8}"
        color: root.theme.distro
        font.family: root.theme.fontFamily
        font.pixelSize: 17

        transform: Rotation {
            id: spin
            origin.x: glyph.width / 2
            origin.y: glyph.height / 2
            angle: 0
        }
        SequentialAnimation {
            id: spinAnim
            NumberAnimation { target: spin; property: "angle"; from: 0; to: 360; duration: 520; easing.type: Easing.OutCubic }
            PropertyAction { target: spin; property: "angle"; value: 0 }
        }
    }

    scale: mouse.pressed ? 0.9 : (mouse.containsMouse ? 1.08 : 1.0)
    Behavior on scale { NumberAnimation { duration: root.theme.durFast; easing.type: Easing.OutBack; easing.overshoot: root.theme.overshoot } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            spinAnim.restart();
            launcher.running = true;
        }
    }

    Process {
        id: launcher
        command: ["qs", "ipc", "call", "launcher", "toggle"]
    }
}

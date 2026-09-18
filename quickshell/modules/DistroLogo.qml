import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    required property Theme theme

    readonly property var glyphs: ({
        artix:  "\u{f31f}",
        arch:   "\u{f303}",
        gentoo: "\u{f08e8}"
    })

    property string distroId: ""
    readonly property string distroGlyph: root.glyphs[root.distroId] ?? "\u{f17c}"

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const os = this.text();
            const id = /^ID=["']?([^"'\n]+)["']?/m.exec(os);
            const like = /^ID_LIKE=["']?([^"'\n]+)["']?/m.exec(os);
            const names = (id ? [id[1]] : []).concat(like ? like[1].split(" ") : []);
            root.distroId = names.find(n => n in root.glyphs) ?? "";
        }
    }

    implicitWidth: 40
    implicitHeight: theme.pillHeight
    radius: theme.radiusSmall
    color: mouse.containsMouse ? theme.pillHover : theme.pill
    antialiasing: true

    Behavior on color { ColorAnimation { duration: theme.durFast } }

    Text {
        id: glyph
        anchors.centerIn: parent
        text: root.distroGlyph
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

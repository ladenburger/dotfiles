import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property Theme theme

    property int percent: 0
    property bool muted: false

    function show(p, m) {
        win.percent = p;
        win.muted = m;
        if (!armed) return;
        hideTimer.restart();
        shown = true;
    }
    property bool shown: false
    property bool armed: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"

    anchors { bottom: true }
    margins { bottom: 90 }
    implicitWidth: 220
    implicitHeight: 56
    color: "transparent"
    exclusiveZone: 0
    visible: shown || fadeOut.running

    Timer {
        interval: 1500
        running: true
        onTriggered: win.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: win.shown = false
    }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: win.theme.radius
        antialiasing: true
        color: Qt.rgba(win.theme.solidBg.r, win.theme.solidBg.g, win.theme.solidBg.b, 1)
        border.width: 1
        border.color: win.theme.border

        opacity: win.shown ? 1 : 0
        transform: Translate { y: win.shown ? 0 : 12 }
        Behavior on opacity { NumberAnimation { id: fadeOut; duration: win.theme.durMed } }

        Row {
            anchors.centerIn: parent
            spacing: 12
            width: parent.width - 32

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.muted || win.percent === 0 ? "\u{f075f}"
                    : (win.percent < 34 ? "\u{f057f}" : (win.percent < 67 ? "\u{f0580}" : "\u{f057e}"))
                color: win.muted ? win.theme.critical : win.theme.audio
                font.family: win.theme.fontFamily
                font.pixelSize: 20
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 64
                height: 6
                radius: height / 2
                antialiasing: true
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    height: parent.height
                    radius: height / 2
                    antialiasing: true
                    width: parent.width * Math.max(0, Math.min(1, win.percent / 100))
                    color: win.muted ? win.theme.muted : win.theme.audio
                    Behavior on width { NumberAnimation { duration: win.theme.durFast; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                horizontalAlignment: Text.AlignRight
                text: win.percent
                color: win.theme.text
                font.family: win.theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}

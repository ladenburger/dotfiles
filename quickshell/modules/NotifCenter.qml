import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    required property Theme theme

    screen: {
        const fm = Hyprland.focusedMonitor;
        if (fm) {
            const m = Quickshell.screens.find(s => s.name === fm.name);
            if (m) return m;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-center"

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: Notifications.centerOpen || closeHold.running
    focusable: Notifications.centerOpen

    Timer {
        id: closeHold
        interval: win.theme.durSlow + 60
    }
    Connections {
        target: Notifications
        function onCenterOpenChanged() {
            if (!Notifications.centerOpen) closeHold.restart();
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Notifications.centerOpen = false
    }

    ClickAway {
        active: Notifications.centerOpen
        onClicked: Notifications.centerOpen = false
    }

    Rectangle {
        id: panel

        readonly property real endRatio: 0.76
        readonly property int screenHeight: win.screen ? win.screen.height : 1080

        anchors { top: parent.top; right: parent.right }
        anchors.topMargin: 0
        anchors.rightMargin: 0
        width: 424
        height: Math.round(panel.screenHeight * panel.endRatio) - win.theme.barBottom

        topLeftRadius: 0
        bottomLeftRadius: win.theme.radius
        topRightRadius: 0
        bottomRightRadius: 0
        color: Qt.rgba(win.theme.frame.r, win.theme.frame.g, win.theme.frame.b, 1)
        antialiasing: true

        transform: Translate {
            x: Notifications.centerOpen ? 0 : panel.width
            Behavior on x {
                NumberAnimation { duration: win.theme.durSlow; easing.type: Easing.OutCubic }
            }
        }

        component Join: CornerWedge {
            corner: 1
            wedgeRadius: win.theme.joinRadius
            wedgeColor: panel.color
        }

        Join {
            x: -width
            y: 0
        }
        Join {
            x: panel.width - win.theme.frameEdge - width
            y: panel.height
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Notifications"
                    color: win.theme.text
                    font.family: win.theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: Notifications.sound ? "\u{f057e}" : "\u{f0581}"
                    color: Notifications.sound ? win.theme.highlight : win.theme.muted
                    font.family: win.theme.fontFamily
                    font.pixelSize: 15
                    Behavior on color { ColorAnimation { duration: win.theme.durFast } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.toggleSound()
                    }
                }

                Rectangle {
                    width: 44
                    height: 24
                    radius: height / 2
                    antialiasing: true
                    color: Notifications.dnd ? win.theme.highlight : win.theme.pill
                    Behavior on color { ColorAnimation { duration: win.theme.durFast } }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: height / 2
                        antialiasing: true
                        y: 3
                        color: win.theme.solidBg
                        x: Notifications.dnd ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: win.theme.durMed; easing.type: Easing.OutBack; easing.overshoot: win.theme.overshoot } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.toggleDnd()
                    }
                }

                Text {
                    text: "\u{f051f}"
                    color: Notifications.dnd ? win.theme.highlight : win.theme.muted
                    font.family: win.theme.fontFamily
                    font.pixelSize: 14
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: Notifications.historyCount + (Notifications.historyCount === 1 ? " notification" : " notifications")
                    color: win.theme.muted
                    font.family: win.theme.fontFamily
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: Notifications.historyCount > 0
                    implicitWidth: clearLabel.implicitWidth + 18
                    implicitHeight: 24
                    radius: win.theme.radiusSmall
                    antialiasing: true
                    color: clearMouse.containsMouse ? win.theme.critical : win.theme.pill
                    Behavior on color { ColorAnimation { duration: win.theme.durFast } }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: win.theme.text
                        font.family: win.theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.clearAll()
                    }
                }
            }

            Text {
                visible: Notifications.historyCount === 0
                Layout.fillWidth: true
                Layout.topMargin: 40
                horizontalAlignment: Text.AlignHCenter
                text: "\u{f05fa}\n\nYou're all caught up"
                color: win.theme.muted
                font.family: win.theme.fontFamily
                font.pixelSize: 13
            }

            ListView {
                id: history
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 10
                model: Notifications.server.trackedNotifications
                cacheBuffer: 8000

                delegate: Item {
                    required property var modelData
                    width: history.width
                    implicitHeight: row.implicitHeight

                    NotifCard {
                        id: row
                        width: parent.width
                        theme: win.theme

                        surface: win.theme.bg
                        notif: parent.modelData
                        showProgress: false
                        onClosed: Notifications.dismiss(parent.modelData)
                    }
                }

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: win.theme.durMed }
                    NumberAnimation { property: "x"; from: 40; to: 0; duration: win.theme.durMed; easing.type: Easing.OutCubic }
                }
                remove: Transition {
                    PropertyAction { property: "ListView.delayRemove"; value: true }
                    NumberAnimation { property: "opacity"; to: 0; duration: win.theme.durFast }
                    NumberAnimation { property: "x"; to: width + 40; duration: win.theme.durMed; easing.type: Easing.InCubic }
                    PropertyAction { property: "ListView.delayRemove"; value: false }
                }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: win.theme.durMed; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}

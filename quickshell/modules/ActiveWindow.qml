import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

Item {
    id: root

    required property Theme theme

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string title: toplevel ? (toplevel.title || toplevel.appId || "") : ""

    implicitWidth: title.length > 0 ? Math.min(row.implicitWidth, 460) : 0
    implicitHeight: theme.pillHeight
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Text {
            id: dot
            text: "\u{f111}"
            color: root.theme.highlight
            font.family: root.theme.fontFamily
            font.pixelSize: 8
            visible: root.title.length > 0
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: label
            text: root.title
            color: root.theme.subtext
            font.family: root.theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            Layout.maximumWidth: 430

            opacity: 0
            transform: Translate { id: slide }
            onTextChanged: fade.restart()

            SequentialAnimation {
                id: fade
                running: true
                ParallelAnimation {
                    NumberAnimation { target: label; property: "opacity"; to: 1; duration: root.theme.durMed }
                    NumberAnimation { target: slide; property: "x"; from: 10; to: 0; duration: root.theme.durMed; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}

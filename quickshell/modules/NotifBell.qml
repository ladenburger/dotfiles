import QtQuick

Item {
    id: root

    required property Theme theme

    readonly property int count: Notifications.historyCount
    readonly property bool dnd: Notifications.dnd

    implicitWidth: pill.implicitWidth
    implicitHeight: theme.pillHeight

    Pill {
        id: pill
        theme: root.theme
        icon: root.dnd ? "\u{f09a1}" : (root.count > 0 ? "\u{f009a}" : "\u{f0099}")
        iconColor: root.dnd ? root.theme.text : (root.count > 0 ? root.theme.highlight : root.theme.subtext)
        pillColor: root.dnd ? root.theme.criticalBg : root.theme.pill
        pillHoverColor: root.dnd ? root.theme.criticalBg : root.theme.pillHover
        active: Notifications.centerOpen
        onClicked: Notifications.centerOpen = !Notifications.centerOpen
        onRightClicked: Notifications.toggleDnd()

        transform: Rotation {
            id: shake
            origin.x: pill.width / 2
            origin.y: pill.height / 2
            angle: 0
        }
    }

    Rectangle {
        visible: root.count > 0 && !root.dnd
        anchors { top: pill.top; right: pill.right }
        anchors.topMargin: -2
        anchors.rightMargin: -2
        width: Math.max(14, badge.implicitWidth + 6)
        height: 14
        radius: height / 2
        color: root.theme.critical

        Text {
            id: badge
            anchors.centerIn: parent
            text: root.count > 9 ? "9+" : root.count
            color: "#ffffff"
            font.family: root.theme.fontFamily
            font.pixelSize: 9
            font.bold: true
        }

        scale: 0
        Component.onCompleted: scale = 1
        onVisibleChanged: if (visible) scale = 1
        Behavior on scale { NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutBack; easing.overshoot: root.theme.overshoot } }
    }

    SequentialAnimation {
        id: shakeAnim
        loops: 2
        NumberAnimation { target: shake; property: "angle"; to: -12; duration: 55 }
        NumberAnimation { target: shake; property: "angle"; to: 12; duration: 90 }
        NumberAnimation { target: shake; property: "angle"; to: 0; duration: 55 }
    }

    Connections {
        target: Notifications
        function onArrived() {
            if (!root.dnd) shakeAnim.restart();
        }
    }
}

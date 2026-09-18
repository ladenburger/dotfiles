import QtQuick

Item {
    id: root

    required property Theme theme

    property bool open: false
    property int padding: 12
    property int minWidth: 0

    default property alias content: contentItem.data

    readonly property bool busy: root.open || closeHold.running

    readonly property bool hovered: panelHover.hovered

    readonly property int fillet: theme.joinRadius
    readonly property real panelWidth: Math.max(root.minWidth, contentItem.width + root.padding * 2)
    readonly property real panelHeight: contentItem.height + root.padding * 2

    implicitWidth: root.panelWidth + root.fillet * 2
    implicitHeight: root.panelHeight

    onOpenChanged: if (!root.open) closeHold.restart()

    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        Timer {
            id: closeHold
            interval: root.theme.durMed + 60
        }

        Rectangle {
            id: panel

            readonly property real fullWidth: root.panelWidth

            x: root.fillet + (panel.fullWidth - panel.width) / 2
            width: root.open ? panel.fullWidth : 0
            height: root.panelHeight
            y: root.open ? 0 : -panel.height

            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.theme.radius
            bottomRightRadius: root.theme.radius
            color: root.theme.bg
            antialiasing: true
            clip: true

            Behavior on y {
                NumberAnimation {
                    duration: root.open ? root.theme.durMed : root.theme.durFast
                    easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: root.open ? root.theme.durMed : root.theme.durFast
                    easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                }
            }

            Behavior on height {
                enabled: root.open && panel.y === 0
                NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutCubic }
            }

            MouseArea { anchors.fill: parent }

            HoverHandler { id: panelHover }

            Item {
                id: contentItem
                anchors.centerIn: parent
                width: childrenRect.width
                height: childrenRect.height
            }
        }

        component Fillet: Item {
            id: fillet
            required property int corner
            readonly property int r: Math.max(0, Math.min(root.fillet, panel.height + panel.y))

            y: 0
            width: fillet.r
            height: fillet.r
            visible: fillet.r > 0

            CornerWedge {
                corner: fillet.corner
                wedgeRadius: fillet.r
                wedgeColor: panel.color
            }
        }

        Fillet {
            corner: 1
            x: panel.x - width
        }
        Fillet {
            corner: 0
            x: panel.x + panel.width
        }
    }
}

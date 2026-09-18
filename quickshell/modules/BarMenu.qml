import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: root

    required property Item anchorItem
    required property Theme theme
    property bool active: false

    readonly property bool opened: root.active
    property int minWidth: 0
    default property alias content: panel.content

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight
    color: "transparent"
    visible: root.active || panel.busy

    grabFocus: root.active

    mask: Region {
        x: root.theme.joinRadius
        y: 0
        width: Math.max(0, root.implicitWidth - root.theme.joinRadius * 2)
        height: root.implicitHeight
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.active
        onCleared: root.active = false
    }

    anchor {
        item: root.anchorItem

        rect: Qt.rect(0, 0, root.anchorItem ? root.anchorItem.width : 0,
                      root.anchorItem ? (root.theme.barHeight + root.anchorItem.height) / 2 : 0)
        edges: Edges.Bottom
        gravity: Edges.Bottom
        adjustment: PopupAdjustment.SlideX
    }

    MenuPanel {
        id: panel
        anchors.fill: parent
        theme: root.theme
        open: root.active
        minWidth: root.minWidth
    }
}

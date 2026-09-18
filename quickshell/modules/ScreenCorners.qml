import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    readonly property Theme theme: Theme {}
    readonly property string monitorName: win.screen ? win.screen.name : ""

    readonly property bool fullscreenHere: Hypr.fullscreenOn(win.monitorName)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screen-corners"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }

    exclusiveZone: -1
    color: "transparent"
    visible: !win.fullscreenHere

    mask: Region {}

    component Corner: CornerWedge {
        wedgeRadius: win.theme.screenRadius
        wedgeColor: "black"
    }

    Corner {
        corner: 0
        anchors { top: parent.top; left: parent.left }
    }
    Corner {
        corner: 1
        anchors { top: parent.top; right: parent.right }
    }
    Corner {
        corner: 2
        anchors { bottom: parent.bottom; right: parent.right }
    }
    Corner {
        corner: 3
        anchors { bottom: parent.bottom; left: parent.left }
    }

    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        anchors.topMargin: win.theme.barHeight
        width: win.theme.frameEdge
        color: win.theme.frame
    }
    Rectangle {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        anchors.topMargin: win.theme.barHeight
        width: win.theme.frameEdge
        color: win.theme.frame
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: win.theme.frameEdge
        color: win.theme.frame
    }

    component FrameCorner: CornerWedge {
        wedgeRadius: win.theme.frameRadius
        wedgeColor: win.theme.frame
    }

    FrameCorner {
        corner: 0
        anchors {
            top: parent.top; topMargin: win.theme.barHeight
            left: parent.left; leftMargin: win.theme.frameEdge
        }
    }
    FrameCorner {
        corner: 1
        anchors {
            top: parent.top; topMargin: win.theme.barHeight
            right: parent.right; rightMargin: win.theme.frameEdge
        }
    }
    FrameCorner {
        corner: 2
        anchors {
            bottom: parent.bottom; bottomMargin: win.theme.frameEdge
            right: parent.right; rightMargin: win.theme.frameEdge
        }
    }
    FrameCorner {
        corner: 3
        anchors {
            bottom: parent.bottom; bottomMargin: win.theme.frameEdge
            left: parent.left; leftMargin: win.theme.frameEdge
        }
    }
}

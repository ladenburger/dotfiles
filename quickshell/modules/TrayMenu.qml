import QtQuick
import QtQuick.Layouts

BarMenu {
    id: root

    property var menuHandle: null

    signal closeRequested

    minWidth: 190

    onActiveChanged: {
        if (menuHandle && menuHandle.sendOpened) {
            if (active) menuHandle.sendOpened();
            else menuHandle.sendClosed();
        }
    }

    ColumnLayout {
        id: list
        width: Math.max(implicitWidth, 166)
        spacing: 0

        TrayMenuLevel {
            theme: root.theme
            handle: root.menuHandle
            depth: 0
            onTriggered: root.closeRequested()
        }
    }
}

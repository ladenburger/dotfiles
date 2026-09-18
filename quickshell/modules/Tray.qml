import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: root

    required property Theme theme
    required property var barWindow

    spacing: 4

    readonly property var openOverrides: ({
        "steam": ["steam", "steam://open/games"]
    })

    function primaryAction(item, fallbackMenu) {
        const id = String(item.id || "");
        for (const key in root.openOverrides) {
            if (id === key || id.indexOf(key) === 0) {
                Quickshell.execDetached(root.openOverrides[key]);
                return;
            }
        }
        item.activate();
        if (item.onlyMenu && item.hasMenu && fallbackMenu)
            fallbackMenu.active = true;
    }

    Repeater {
        model: SystemTray.items ? SystemTray.items.values : []

        delegate: Item {
            id: entry
            required property var modelData

            implicitWidth: 26
            implicitHeight: root.theme.pillHeight
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: root.theme.radiusSmall
                color: mouse.containsMouse ? root.theme.pillHover : "transparent"
                Behavior on color { ColorAnimation { duration: root.theme.durFast } }
            }

            Image {
                id: img
                anchors.centerIn: parent
                width: 18
                height: 18
                source: entry.modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                sourceSize.width: 36
                sourceSize.height: 36

                scale: entered ? (mouse.pressed ? 0.82 : (mouse.containsMouse ? 1.18 : 1.0)) : 0.5
                opacity: entered ? 1 : 0
                property bool entered: false
                Component.onCompleted: entered = true
                Behavior on scale { NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutBack; easing.overshoot: root.theme.overshoot } }
                Behavior on opacity { NumberAnimation { duration: root.theme.durMed } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouseEvt => {
                    if (mouseEvt.button === Qt.RightButton) {
                        if (entry.modelData.hasMenu) menu.active = true;
                        else entry.modelData.secondaryActivate();
                    } else if (mouseEvt.button === Qt.MiddleButton) {
                        entry.modelData.secondaryActivate();
                    } else {
                        root.primaryAction(entry.modelData, menu);
                    }
                }
                onWheel: wheelEvt => entry.modelData.scroll(wheelEvt.angleDelta.y, false)
            }

            TrayMenu {
                id: menu
                theme: root.theme
                anchorItem: entry
                menuHandle: entry.modelData.menu
                onCloseRequested: menu.active = false
            }
        }
    }
}

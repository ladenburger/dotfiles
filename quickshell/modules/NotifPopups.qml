import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

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
    WlrLayershell.namespace: "quickshell-notifications"

    anchors { top: true; right: true }

    margins { top: theme.barBottom + theme.barMargin; right: 0 }

    implicitWidth: 400
    implicitHeight: Math.max(1, Math.min(list.contentHeight + 4, (screen ? screen.height : 1080) - theme.barBottom - 40))
    color: "transparent"
    exclusiveZone: 0

    visible: Notifications.popups.count > 0 && !Notifications.centerOpen

    mask: Region { item: list }

    ListView {
        id: list
        anchors.fill: parent
        spacing: 10
        interactive: false
        model: Notifications.popups
        cacheBuffer: 4000
        verticalLayoutDirection: ListView.TopToBottom

        delegate: Item {
            id: slot
            required property var model
            width: list.width
            implicitHeight: card.implicitHeight

            readonly property var notif: Notifications.notif(model.sid)

            NotifCard {
                id: card
                width: parent.width
                theme: win.theme
                notif: slot.notif
                flushRight: true
                showProgress: true
                timeout: slot.notif && slot.notif.urgency === NotificationUrgency.Low ? 4000 : 6000

                onClosed: {
                    Notifications.dropPopup(slot.model.sid);
                    Notifications.dismiss(slot.notif);
                }
                onExpired: Notifications.dropPopup(slot.model.sid)
                onActivated: Notifications.centerOpen = false
            }
        }

        add: Transition {
            NumberAnimation { property: "x"; from: win.width; to: 0; duration: win.theme.durMed; easing.type: Easing.OutCubic }
        }
        remove: Transition {
            PropertyAction { property: "ListView.delayRemove"; value: true }
            NumberAnimation { property: "x"; to: win.width; duration: win.theme.durMed; easing.type: Easing.InCubic }
            PropertyAction { property: "ListView.delayRemove"; value: false }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: win.theme.durMed; easing.type: Easing.OutCubic }
        }
        move: Transition {
            NumberAnimation { property: "y"; duration: win.theme.durMed; easing.type: Easing.OutCubic }
        }
    }
}

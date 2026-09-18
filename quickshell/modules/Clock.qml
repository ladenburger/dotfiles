import QtQuick

Item {
    id: root

    required property Theme theme
    property date now: new Date()

    implicitWidth: pill.implicitWidth
    implicitHeight: theme.pillHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Pill {
        id: pill
        theme: root.theme
        icon: "\u{f017}"
        iconColor: root.theme.highlight
        label: Qt.formatDateTime(root.now, "ddd, MMM d  •  h:mm AP")
        labelColor: root.theme.text
        active: cal.active
        onClicked: cal.active = !cal.active
    }

    CalendarPopup {
        id: cal
        anchorItem: pill
        theme: root.theme
        now: root.now
    }
}

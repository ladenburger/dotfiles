import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

Item {
    id: root

    required property Theme theme

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev && dev.isLaptopBattery && dev.isPresent
    readonly property int percent: dev ? Math.round(dev.percentage) : 0
    readonly property bool charging: dev
        && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: dev && dev.state === UPowerDeviceState.FullyCharged
    readonly property bool low: present && !charging && percent <= 15
    readonly property bool warn: present && !charging && percent <= 30

    readonly property string timeLeft: {
        if (!root.dev) return "";
        const secs = root.charging ? root.dev.timeToFull : root.dev.timeToEmpty;
        if (!secs || secs <= 0) return "";
        const h = Math.floor(secs / 3600);
        const m = Math.round((secs % 3600) / 60);
        return (h > 0 ? h + "h " : "") + m + "m";
    }

    readonly property color accent: root.low ? root.theme.critical
        : (root.charging ? root.theme.good : (root.warn ? root.theme.warn : root.theme.good))

    readonly property var ramp: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}",
                                 "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]

    function glyph() {
        if (charging) return "\u{f0084}";
        if (full) return "\u{f0079}";
        return ramp[Math.max(0, Math.min(10, Math.round(percent / 10)))];
    }

    visible: present
    implicitWidth: present ? pill.implicitWidth : 0
    implicitHeight: theme.pillHeight

    Pill {
        id: pill
        theme: root.theme
        icon: root.glyph()
        iconColor: root.low ? root.theme.text : root.accent
        label: root.percent + "%"
        pillColor: root.low ? root.theme.criticalBg : root.theme.pill
        pillHoverColor: root.low ? root.theme.criticalBg : root.theme.pillHover
        active: menu.active
        onClicked: menu.active = !menu.active
    }

    BarMenu {
        id: menu
        anchorItem: pill
        theme: root.theme

        ColumnLayout {
            width: 230
            spacing: 12

            Text {
                text: "Battery"
                color: root.theme.text
                font.family: root.theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Gauge {
                Layout.alignment: Qt.AlignHCenter
                theme: root.theme
                open: menu.opened
                glyph: root.glyph()
                caption: root.charging ? "Charging" : (root.full ? "Full" : "On battery")
                accent: root.accent
                critical: root.low
                value: root.percent / 100
                amount: root.percent
                suffix: "%"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.theme.borderDim
            }

            Line {
                theme: root.theme
                key: root.charging ? "Until full" : "Remaining"
                val: root.timeLeft
                visible: root.timeLeft.length > 0
            }

            Line {
                theme: root.theme
                key: "Rate"
                val: root.dev ? Math.abs(root.dev.changeRate).toFixed(1) + " W" : ""
                visible: !!root.dev && root.dev.changeRate !== 0
            }

            Line {
                theme: root.theme
                key: "Health"
                val: root.dev ? Math.round(root.dev.healthPercentage) + "%" : ""
                visible: !!root.dev && root.dev.healthSupported
            }
        }
    }

    component Line: RowLayout {
        id: line
        required property Theme theme
        required property string key
        required property string val
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: line.key
            color: line.theme.subtext
            font.family: line.theme.fontFamily
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            text: line.val
            color: line.theme.text
            font.family: line.theme.fontFamily
            font.pixelSize: 12
        }
    }

    Rectangle {
        visible: root.charging
        anchors.right: pill.right
        anchors.top: pill.top
        anchors.margins: 3
        width: 5
        height: 5
        radius: height / 2
        color: root.theme.good
        SequentialAnimation on opacity {
            running: root.charging
            loops: Animation.Infinite
            NumberAnimation { from: 0.25; to: 1; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0.25; duration: 900; easing.type: Easing.InOutSine }
        }
    }
}

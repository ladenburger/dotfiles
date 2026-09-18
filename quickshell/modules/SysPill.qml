import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Theme theme

    readonly property real tempMax: 100

    property real shownTemp: 0
    property real shownMem: 0
    property real shownCpu: 0

    Behavior on shownTemp { NumberAnimation { duration: root.theme.durSlow; easing.type: Easing.OutCubic } }
    Behavior on shownMem { NumberAnimation { duration: root.theme.durSlow; easing.type: Easing.OutCubic } }
    Behavior on shownCpu { NumberAnimation { duration: root.theme.durSlow; easing.type: Easing.OutCubic } }

    Connections {
        target: Sys
        function onTempCChanged() { root.shownTemp = Sys.tempC }
        function onMemUsedGiBChanged() { root.shownMem = Sys.memUsedGiB }
        function onCpuPercChanged() { root.shownCpu = Sys.cpuPerc }
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    component Stat: RowLayout {
        id: stat
        required property string glyph
        required property color accent
        required property string value
        required property Theme theme
        spacing: 5

        Text {
            text: stat.glyph
            color: Sys.tempCritical ? stat.theme.text : stat.accent
            font.family: stat.theme.fontFamily
            font.pixelSize: 14
            Behavior on color { ColorAnimation { duration: stat.theme.durMed } }
        }

        Text {
            text: stat.value
            color: stat.theme.text
            font.family: stat.theme.fontFamily
            font.pixelSize: 13
        }
    }

    Pill {
        id: pill
        theme: root.theme
        active: menu.active
        pillColor: Sys.tempCritical ? root.theme.criticalBg : root.theme.pill
        pillHoverColor: Sys.tempCritical ? root.theme.criticalBg : root.theme.pillHover
        onClicked: menu.active = !menu.active

        Stat {
            theme: root.theme
            glyph: "\u{f050f}"
            accent: root.theme.temp
            value: Sys.tempC >= 0 ? root.shownTemp.toFixed(0) + "°" : "--"
        }

        Stat {
            theme: root.theme
            Layout.leftMargin: 5
            glyph: "\u{f035b}"
            accent: root.theme.mem
            value: root.shownMem.toFixed(1) + "G"
        }

        Stat {
            theme: root.theme
            Layout.leftMargin: 5
            glyph: "\u{f0ee0}"
            accent: root.theme.cpu
            value: root.shownCpu.toFixed(0) + "%"
        }
    }

    BarMenu {
        id: menu
        anchorItem: pill
        theme: root.theme

        ColumnLayout {
            width: 320
            spacing: 12

            Text {
                text: "System"
                color: root.theme.text
                font.family: root.theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Gauge {
                    Layout.fillWidth: true
                    theme: root.theme
                    open: menu.opened
                    glyph: "\u{f0ee0}"
                    caption: "CPU"
                    accent: root.theme.cpu
                    value: Sys.cpuPerc / 100
                    amount: Sys.cpuPerc
                    suffix: "%"
                }

                Gauge {
                    Layout.fillWidth: true
                    theme: root.theme
                    open: menu.opened
                    glyph: "\u{f035b}"
                    caption: "Memory"
                    accent: root.theme.mem
                    value: Sys.memPerc / 100
                    amount: Sys.memUsedGiB
                    decimals: 1
                    suffix: "G"
                }

                Gauge {
                    Layout.fillWidth: true
                    theme: root.theme
                    open: menu.opened
                    glyph: "\u{f050f}"
                    caption: "Temp"
                    accent: root.theme.temp
                    critical: Sys.tempCritical
                    visible: Sys.tempC >= 0
                    value: Sys.tempC / root.tempMax
                    amount: Sys.tempC
                    suffix: "°"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.theme.borderDim
            }

            DetailRow {
                theme: root.theme
                key: "Load average"
                val: Sys.loadAvg.map(v => v.toFixed(2)).join("  ")
            }

            DetailRow {
                theme: root.theme
                key: "Memory"
                val: Sys.memUsedGiB.toFixed(1) + " / " + Sys.memTotalGiB.toFixed(1) + " GiB"
            }
        }
    }

    component DetailRow: RowLayout {
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
}

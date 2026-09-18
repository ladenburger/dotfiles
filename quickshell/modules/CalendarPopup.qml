import QtQuick
import QtQuick.Layouts

BarMenu {
    id: root

    required property date now
    property date shown: new Date(now.getFullYear(), now.getMonth(), 1)

    function shiftMonth(delta) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + delta, 1);
        slide.from = delta > 0 ? 24 : -24;
        slide.restart();
    }

    onActiveChanged: if (active) shown = new Date(now.getFullYear(), now.getMonth(), 1)

    readonly property var monthName: Qt.formatDate(shown, "MMMM yyyy")
    readonly property int firstWeekday: {

        const d = shown.getDay();
        return (d + 6) % 7;
    }
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()

    ColumnLayout {
        width: 268
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            NavButton {
                theme: root.theme
                glyph: "\u{f0141}"
                onClicked: root.shiftMonth(-1)
            }

            Text {
                text: root.monthName
                color: root.theme.text
                font.family: root.theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            NavButton {
                theme: root.theme
                glyph: "\u{f0142}"
                onClicked: root.shiftMonth(1)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: root.theme.muted
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight
            clip: true

            GridLayout {
                id: grid
                width: parent.width
                columns: 7
                rowSpacing: 2
                columnSpacing: 0

                property real slx: 0
                transform: Translate { x: grid.slx }
                NumberAnimation {
                    id: slide
                    target: grid
                    property: "slx"
                    from: 0
                    to: 0
                    duration: root.theme.durMed
                    easing.type: Easing.OutCubic
                }
                Component.onCompleted: grid.slx = 0

                Repeater {
                    model: 42
                    delegate: Item {
                        required property int index
                        readonly property int dayNum: index - root.firstWeekday + 1
                        readonly property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth
                        readonly property bool isToday: inMonth
                            && dayNum === root.now.getDate()
                            && root.shown.getMonth() === root.now.getMonth()
                            && root.shown.getFullYear() === root.now.getFullYear()

                        Layout.fillWidth: true
                        implicitHeight: 30

                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: root.theme.radiusSmall
                            antialiasing: true
                            color: parent.isToday ? root.theme.highlight : "transparent"
                            scale: parent.isToday ? 1 : 0
                            Behavior on scale { NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutBack; easing.overshoot: root.theme.overshoot } }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: parent.inMonth
                            text: parent.dayNum
                            color: parent.isToday ? root.theme.solidBg
                                : (parent.index % 7 >= 5 ? root.theme.subtext : root.theme.text)
                            font.family: root.theme.fontFamily
                            font.pixelSize: 12
                            font.bold: parent.isToday
                        }
                    }
                }
            }
        }
    }

    component NavButton: Rectangle {
        id: nav
        required property Theme theme
        property string glyph: ""
        signal clicked

        implicitWidth: 26
        implicitHeight: 26
        radius: nav.theme.radiusSmall
        antialiasing: true
        color: navMouse.containsMouse ? theme.pillHover : "transparent"
        Behavior on color { ColorAnimation { duration: theme.durFast } }

        Text {
            anchors.centerIn: parent
            text: nav.glyph
            color: nav.theme.subtext
            font.family: nav.theme.fontFamily
            font.pixelSize: 14
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }
}

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: theme.text
    property color labelColor: theme.text
    property color pillColor: theme.pill
    property color pillHoverColor: theme.pillHover
    property bool active: false
    property bool hovered: mouseArea.containsMouse
    property bool pressed: mouseArea.pressed
    required property Theme theme

    signal clicked
    signal rightClicked
    signal wheel(int angleDelta)

    default property alias body: row.data

    implicitWidth: row.implicitWidth + 24
    implicitHeight: theme.pillHeight
    radius: theme.radiusSmall
    color: active || mouseArea.containsMouse ? pillHoverColor : pillColor
    antialiasing: true

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.pressed ? 0.94 : (root.hovered ? 1.04 : 1.0)
        yScale: xScale
        Behavior on xScale { NumberAnimation { duration: root.theme.durFast; easing.type: Easing.OutCubic } }
    }

    Behavior on color { ColorAnimation { duration: theme.durFast } }
    Behavior on implicitWidth { NumberAnimation { duration: root.theme.durMed; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.icon
            visible: root.icon.length > 0
            color: root.iconColor
            font.family: root.theme.fontFamily
            font.pixelSize: 14
            Behavior on color { ColorAnimation { duration: root.theme.durMed } }
        }

        Text {
            text: root.label
            visible: root.label.length > 0
            color: root.labelColor
            font.family: root.theme.fontFamily
            font.pixelSize: 13
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: root.theme.durMed } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheel => root.wheel(wheel.angleDelta.y)
    }
}

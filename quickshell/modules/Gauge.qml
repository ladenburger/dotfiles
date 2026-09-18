import QtQuick
import QtQuick.Shapes

Item {
    id: root

    required property Theme theme

    property real value: 0

    property real amount: 0
    property int decimals: 0
    property string suffix: ""
    property string glyph: ""
    property string caption: ""
    property color accent: theme.highlight
    property bool critical: false

    property int size: 96
    property int thickness: 8

    property int captionWidth: 0
    property bool open: true

    readonly property color ringColor: root.critical ? root.theme.critical : root.accent

    property real shownValue: root.open ? Math.max(0, Math.min(1, root.value)) : 0
    property real shownAmount: root.open ? root.amount : 0

    Behavior on shownValue {
        NumberAnimation { duration: root.theme.durSlow; easing.type: Easing.OutCubic }
    }
    Behavior on shownAmount {
        NumberAnimation { duration: root.theme.durSlow; easing.type: Easing.OutCubic }
    }

    implicitWidth: Math.max(root.size, capt.visible ? capt.width : 0)
    implicitHeight: root.size + (root.caption.length > 0 ? capt.implicitHeight + 6 : 0)

    Item {
        id: ring
        width: root.size
        height: root.size
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property real radius: (root.size - root.thickness) / 2

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            asynchronous: false

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.theme.pill
                strokeWidth: root.thickness
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: root.size / 2
                    centerY: root.size / 2
                    radiusX: ring.radius
                    radiusY: ring.radius
                    startAngle: -90
                    sweepAngle: 360
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.ringColor
                strokeWidth: root.thickness
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: root.size / 2
                    centerY: root.size / 2
                    radiusX: ring.radius
                    radiusY: ring.radius
                    startAngle: -90

                    sweepAngle: Math.max(0.01, 360 * root.shownValue)
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.glyph
                visible: root.glyph.length > 0
                color: root.ringColor
                font.family: root.theme.fontFamily
                font.pixelSize: Math.round(root.size * 0.19)
                Behavior on color { ColorAnimation { duration: root.theme.durMed } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.shownAmount.toFixed(root.decimals) + root.suffix
                color: root.theme.text
                font.family: root.theme.fontFamily
                font.pixelSize: Math.round(root.size * 0.2)
                font.bold: true
            }
        }
    }

    Text {
        id: capt
        anchors.top: ring.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.caption
        visible: root.caption.length > 0
        color: root.theme.subtext
        font.family: root.theme.fontFamily
        font.pixelSize: 11
        width: root.captionWidth > 0 ? Math.min(implicitWidth, root.captionWidth) : implicitWidth
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }
}

import QtQuick

Item {
    id: root

    required property Theme theme
    required property var wall

    Loader {
        anchors.fill: parent
        active: root.wall.geo !== null
        sourceComponent: meter
    }

    Component {
        id: meter

        Item {
            id: face
            anchors.fill: parent

            Component.onCompleted: Cava.listeners++
            Component.onDestruction: Cava.listeners = Math.max(0, Cava.listeners - 1)

            opacity: Cava.quiet ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: root.theme.durSlow } }

            readonly property var g: root.wall.geo

            Repeater {
                model: Cava.values.length

                Rectangle {
                    id: bar
                    required property int index

                    readonly property real slot:
                        (face.g.right - face.g.left) / Cava.values.length
                    readonly property real centre:
                        face.g.left + (index + 0.5) * slot
                    readonly property real level:
                        Math.max(0, Math.min(100, Cava.values[index] ?? 0))

                    x: root.wall.sx(bar.centre - bar.slot * (1 - face.g.gap) / 2)
                    width: bar.slot * (1 - face.g.gap) * root.wall.fit
                    y: root.wall.sy(root.wall.levelY(bar.level, bar.centre))
                    height: Math.max(0, root.wall.sy(root.wall.levelY(0, bar.centre)) - bar.y)

                    transformOrigin: Item.Bottom
                    rotation: root.wall.leanDeg

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#3d000000" }
                        GradientStop { position: 1.0; color: "#5c000000" }
                    }
                }
            }

            Repeater {
                model: face.g.levels

                Text {
                    required property var modelData

                    text: modelData.percent
                    color: root.theme.subtext

                    opacity: 0.55
                    font.family: root.theme.fontFamily
                    font.pixelSize: Math.round(face.g.labelSize * root.wall.fit)

                    x: root.wall.sx(face.g.labelRight
                                    + root.wall.leanX(modelData.percent, face.g.labelRight))
                       - width
                    y: root.wall.sy(root.wall.levelY(modelData.percent,
                                                     face.g.labelRight)) - height / 2
                }
            }
        }
    }
}

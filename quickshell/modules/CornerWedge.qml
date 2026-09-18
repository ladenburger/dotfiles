import QtQuick
import QtQuick.Shapes

Shape {
    id: wedge

    required property int corner
    property int wedgeRadius: 12
    property color wedgeColor: "black"

    width: wedgeRadius
    height: wedgeRadius
    rotation: corner * 90
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: wedge.wedgeColor
        strokeWidth: 0
        strokeColor: "transparent"

        startX: 0
        startY: 0
        PathLine { x: wedge.wedgeRadius; y: 0 }
        PathArc {
            x: 0
            y: wedge.wedgeRadius
            radiusX: wedge.wedgeRadius
            radiusY: wedge.wedgeRadius
            direction: PathArc.Counterclockwise
        }
        PathLine { x: 0; y: 0 }
    }
}

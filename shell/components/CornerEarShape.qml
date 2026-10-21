import QtQuick
import QtQuick.Shapes
import "../config"
import "../logic/earGeometry.mjs" as EarGeometry

// Black corner outline: `anchor` is the square screen corner
// ("topLeft", "topRight", "bottomRight" or "bottomLeft").
Shape {
    id: root

    property string anchor: "topLeft"

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: Colours.background
        strokeWidth: -1

        PathSvg {
            path: EarGeometry.cornerPath(root.width, root.height, root.anchor, Layout.earRadius, Layout.cornerRadius) ?? ""
        }
    }
}

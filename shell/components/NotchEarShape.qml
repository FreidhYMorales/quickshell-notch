import QtQuick
import QtQuick.Shapes
import "../config"
import "../logic/earGeometry.mjs" as EarGeometry

// Black notch outline: concave top ears, rounded bottom corners.
Shape {
    id: root

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: Colours.background
        strokeWidth: -1

        PathSvg {
            path: EarGeometry.notchPath(root.width, root.height, Layout.earRadius, Layout.cornerRadius)
        }
    }
}

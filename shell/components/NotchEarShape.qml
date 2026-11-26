import QtQuick
import QtQuick.Shapes
import "../config"
import "../logic/earGeometry.mjs" as EarGeometry

// Black notch with one continuous accent around its exposed silhouette,
// excluding the screen-flush top edge.
Item {
    id: root

    property color accentColor: Colours.global.primary
    property real accentOpacity: 1

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Colours.background
            strokeWidth: -1

            PathSvg {
                path: EarGeometry.notchPath(root.width, root.height, Layout.earRadius, Layout.cornerRadius)
            }
        }
    }

    NotchEdgeAccent {
        anchors.fill: parent
        path: EarGeometry.notchOutlinePath(root.width, root.height, Layout.earRadius, Layout.cornerRadius)
        accentColor: root.accentColor
        opacity: root.accentOpacity
    }
}

import QtQuick
import QtQuick.Shapes
import "../config"
import "../logic/earGeometry.mjs" as EarGeometry

// Black corner shape with an accent along its exposed lower contour.
Item {
    id: root

    property string anchor: "topLeft"
    property color accentColor: Colours.global.primary

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Colours.background
            strokeWidth: -1

            PathSvg {
                path: EarGeometry.cornerPath(root.width, root.height, root.anchor, Layout.earRadius, Layout.cornerRadius) ?? ""
            }
        }
    }

    NotchEdgeAccent {
        anchors.fill: parent
        path: EarGeometry.cornerOutlinePath(root.width, root.height, root.anchor, Layout.earRadius, Layout.cornerRadius) ?? ""
        accentColor: root.accentColor
    }
}

import QtQuick
import QtQuick.Shapes
import "../config"

// A single fine outline on the exposed silhouette.
Shape {
    id: root

    property string path: ""
    property color accentColor: Colours.global.primary

    visible: path !== ""
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeWidth: Colours.notchEdgeWidth
        capStyle: ShapePath.FlatCap
        joinStyle: ShapePath.RoundJoin
        strokeGradient: LinearGradient {
            x1: 0
            y1: root.height
            x2: root.width
            y2: root.height

            GradientStop {
                position: 0
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, Colours.notchEdgeAlpha * 0.45)
            }

            GradientStop {
                position: 0.5
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, Colours.notchEdgeAlpha)
            }

            GradientStop {
                position: 1
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, Colours.notchEdgeAlpha * 0.45)
            }
        }

        PathSvg {
            path: root.path
        }
    }
}

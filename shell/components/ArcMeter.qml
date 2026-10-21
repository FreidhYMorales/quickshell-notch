import QtQuick
import QtQuick.Shapes
import "../config"

// Compact circular progress ring with a centred glyph, for the idle row's
// CPU and RAM meters. `value` is 0-100 (the SysInfo convention). A stroked
// PathAngleArc needs no masking.
Item {
    id: root

    property real value: 0
    property string icon: ""
    property color ringColor: Colours.fallback.primary
    property color trackColor: Qt.alpha(ringColor, Colours.trackAlpha)
    property color iconColor: ringColor
    property real ringWidth: Layout.arcRing
    property real iconPixelSize: Layout.arcIcon

    readonly property real radius: Math.min(width, height) / 2 - ringWidth / 2
    readonly property real sweep: 360 * Math.max(0, Math.min(100, value)) / 100

    implicitWidth: Layout.arcSize
    implicitHeight: Layout.arcSize

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Track: 359.99, because a true 360 sweep can render as an empty path.
        ShapePath {
            strokeColor: root.trackColor
            fillColor: "transparent"
            strokeWidth: root.ringWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: -90
                sweepAngle: 359.99
            }
        }

        ShapePath {
            strokeColor: root.ringColor
            fillColor: "transparent"
            strokeWidth: root.ringWidth
            capStyle: ShapePath.RoundCap

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Timings.animNormal
                    easing.type: Easing.InOutCubic
                }
            }

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: -90
                sweepAngle: root.sweep

                Behavior on sweepAngle {
                    Anim {}
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Fonts.family
        font.pixelSize: root.iconPixelSize
        color: root.iconColor
    }
}

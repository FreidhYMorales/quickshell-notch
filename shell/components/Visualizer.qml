pragma ComponentBehavior: Bound

import QtQuick
import "../config"
import "../services"
import "../logic/visualizer.mjs" as Viz

// Mirrored bars: a flat line at rest, growing up and down from the centre
// line. Hidden (and zero wide) when cava is unavailable. No Behavior on the
// bar height: frames already arrive at Limits.cavaFps.
Item {
    id: root

    property var levels: Cava.levels
    property color barColor: Colours.global.primary

    readonly property var bars: Viz.barGeometry(levels, {
        height: Layout.vizHeight,
        barWidth: Layout.vizBarWidth,
        gap: Layout.vizGap,
        minHeight: Layout.vizMinHeight
    })

    visible: Cava.available
    implicitWidth: Cava.available ? levels.length * (Layout.vizBarWidth + Layout.vizGap) - Layout.vizGap : 0
    implicitHeight: Layout.vizHeight

    Repeater {
        model: root.bars

        Rectangle {
            required property var modelData

            x: modelData.x
            y: modelData.y
            width: Layout.vizBarWidth
            height: modelData.height
            radius: width / 2
            color: root.barColor
        }
    }
}

pragma Singleton

import Quickshell

Singleton {
    // Logical units, identical on every monitor.
    readonly property int idleHeight: 32
    readonly property int cornerWidth: 200
    readonly property int osdWidth: 220
    readonly property int gap: 8
    readonly property int earRadius: 12
    readonly property int cornerRadius: 18

    // Idle centre notch width, including the 2 * earRadius flare of its ears.
    readonly property int idleWidth: 260

    // Centre width cap; layoutFor shrinks it further on narrow screens.
    readonly property int centerMaxWidth: 600
    readonly property var centerMaxWidthByMonitor: ({})

    // Idle battery layers reserve this much on each side of the clock.
    readonly property int batterySide: 36

    // Idle row: arc meters, overlay dots and the gap between row items.
    readonly property int arcSize: 20
    readonly property real arcRing: 2.5
    readonly property int arcIcon: 9
    readonly property int dotSize: 6
    readonly property int rowGap: 8

    // Expanded centre notch: full width with a player, narrower clock card alone.
    readonly property int expandedHeight: 180
    readonly property int expandedWidth: 560
    readonly property int expandedClockWidth: 300

    // Bundle in the shape expected by logic/surfaceLayout.mjs.
    readonly property var tokens: ({
            idleHeight: idleHeight,
            cornerWidth: cornerWidth,
            osdWidth: osdWidth,
            gap: gap,
            centerMaxWidth: centerMaxWidth,
            centerMaxWidthByMonitor: centerMaxWidthByMonitor,
            expandedHeight: expandedHeight
        })
}

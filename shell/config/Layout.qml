pragma Singleton

import Quickshell

Singleton {
    // Logical units, identical on every monitor.
    readonly property int idleHeight: 32
    readonly property int cornerWidth: 200
    readonly property int osdWidth: 220
    readonly property int gap: 8
    readonly property int earRadius: 12
    readonly property int cornerRadius: 12

    // Idle centre notch width, including the 2 * earRadius flare of its ears.
    readonly property int idleWidth: 260

    // Centre width cap; layoutFor shrinks it further on narrow screens.
    readonly property int centerMaxWidth: 600
    readonly property var centerMaxWidthByMonitor: ({})

    // Bundle in the shape expected by logic/surfaceLayout.mjs.
    readonly property var tokens: ({
            idleHeight: idleHeight,
            cornerWidth: cornerWidth,
            osdWidth: osdWidth,
            gap: gap,
            centerMaxWidth: centerMaxWidth,
            centerMaxWidthByMonitor: centerMaxWidthByMonitor
        })
}

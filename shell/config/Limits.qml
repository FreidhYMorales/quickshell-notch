pragma Singleton

import Quickshell

// Thresholds that are neither flags nor geometry.
Singleton {
    // Battery percentage below which the idle notch shows the low layer.
    readonly property int batteryLow: 20
    // At or below this (unplugged) the one-shot critical event fires.
    readonly property int batteryCritical: 10
    // cava visualizer: bars, frames per second and the ascii range of a bar.
    readonly property int cavaBars: 6
    readonly property int cavaFps: 30
    readonly property int cavaMaxRange: 100
    // Restarts of a dead cava per play session before the visualizer gives up.
    readonly property int cavaRetries: 3
    // Art colours darker than this (luma 0-1) are not used as the accent.
    readonly property real accentMinLuma: 0.25
    // Workspace slots shown at least (more when the active or an occupied id is higher).
    readonly property int workspaceSlots: 5
    // A floating window smaller than this is a popup, not an app.
    readonly property int floatMinWidth: 300
    readonly property int floatMinHeight: 200
    // Days shown on each side of today in the week strip.
    readonly property int weekRadius: 3
}

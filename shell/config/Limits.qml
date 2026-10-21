pragma Singleton

import Quickshell

// Thresholds that are neither flags nor geometry.
Singleton {
    // Battery percentage below which the idle notch shows the low layer.
    readonly property int batteryLow: 20
    // At or below this (unplugged) the one-shot critical event fires.
    readonly property int batteryCritical: 10
    // Days shown on each side of today in the week strip.
    readonly property int weekRadius: 3
}

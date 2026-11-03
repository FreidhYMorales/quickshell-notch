pragma Singleton

import Quickshell

Singleton {
    // The spacer reserves the idle notch height as an exclusive zone.
    readonly property bool reserveSpace: true
    // Draw placeholder surfaces for notches that are not built yet.
    readonly property bool showPlaceholders: false
    // Smoke runs load the config without touching the live session.
    // Dev only: forces battery fields, e.g. ({ percentage: 19, plugged: false }).
    // Null keeps the real values.
    readonly property var batteryOverride: null
    readonly property bool smoke: Quickshell.env("NOTCH_SMOKE") === "1"
    // Power actions are only logged, never run: smoke runs and manual tests
    // (NOTCH_POWER_DRY_RUN=1) must not end the live session.
    readonly property bool powerDryRun: smoke || Quickshell.env("NOTCH_POWER_DRY_RUN") === "1"
}

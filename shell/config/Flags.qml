pragma Singleton

import Quickshell

Singleton {
    // The spacer reserves the idle notch height as an exclusive zone.
    readonly property bool reserveSpace: true
    // Draw placeholder surfaces for notches that are not built yet.
    readonly property bool showPlaceholders: false
    // Smoke runs load the config without touching the live session.
    readonly property bool smoke: Quickshell.env("NOTCH_SMOKE") === "1"
}

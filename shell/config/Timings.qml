pragma Singleton

import Quickshell

Singleton {
    // Interaction (milliseconds)
    readonly property int hoverOpen: 200
    readonly property int hoverDebounce: 50
    readonly property int reveal: 1500
    readonly property int holdConfirm: 1000
    // Workspace events within this window become one snapshot.
    readonly property int wsDebounce: 150
    // Triggers are ignored this long after startup (initial reads are not news).
    readonly property int startupGate: 1000

    // Unread dot blink half-period (milliseconds).
    readonly property int blink: 700

    // Polling (milliseconds)
    readonly property int sysPoll: 2000

    // Wait before restarting a cava that exited while a player is playing.
    readonly property int cavaRestart: 2000

    // Animation durations (milliseconds)
    readonly property int animFast: 120
    readonly property int animNormal: 220
    readonly property int animSlow: 400
}

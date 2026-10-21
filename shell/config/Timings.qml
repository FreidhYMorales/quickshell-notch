pragma Singleton

import Quickshell

Singleton {
    // Interaction (milliseconds)
    readonly property int hoverOpen: 200
    readonly property int hoverDebounce: 50
    readonly property int reveal: 1500
    readonly property int holdConfirm: 1000

    // Polling (milliseconds)
    readonly property int sysPoll: 2000

    // Animation durations (milliseconds)
    readonly property int animFast: 120
    readonly property int animNormal: 220
    readonly property int animSlow: 400
}

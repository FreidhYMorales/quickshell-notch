pragma Singleton

import Quickshell

Singleton {
    // Interaction (milliseconds)
    readonly property int hoverOpen: 200
    readonly property int hoverDebounce: 50
    // Pointer leave long enough to close a subpage (a brief one keeps it).
    readonly property int ccLeave: 1200
    readonly property int reveal: 1500
    readonly property int holdConfirm: 1000
    // One sweep of the polkit fingerprint scan line.
    readonly property int polkitScan: 1200
    // Pause before the lock fingerprint listener restarts after a failed
    // scan, so fprintd has released the device.
    readonly property int lockFingerprintRetry: 300
    // How long a notification toast shows (paused while hovered).
    readonly property int toast: 5000
    // Workspace events within this window become one snapshot.
    readonly property int wsDebounce: 150
    // Triggers are ignored this long after startup (initial reads are not news).
    readonly property int startupGate: 1000
    readonly property int recordingCountdownTick: 1000
    readonly property int recordingReadyTimeout: 15000
    // A recording helper (mkdir, mktemp, ln, sh) is killed after this long.
    readonly property int recordingHelperTimeout: 5000

    // Unread dot blink half-period (milliseconds).
    readonly property int blink: 700

    // Polling (milliseconds)
    readonly property int sysPoll: 2000
    // Uptime refresh; the control center shows whole minutes.
    readonly property int uptimePoll: 30000

    // Wait before restarting a cava that exited while a player is playing.
    readonly property int cavaRestart: 2000

    // Animation durations (milliseconds)
    readonly property int animFast: 120
    readonly property int animNormal: 220
    readonly property int animSlow: 400
}

pragma Singleton

import Quickshell
import "motion.mjs" as Motion

// Animation durations come from `motion.mjs` so the greetd login surface, a
// separate entrypoint, moves with the same tokens.
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
    // Screenshot is cosmetic: do not let it delay a lock indefinitely.
    readonly property int lockCaptureTimeout: 500
    // The black stage paints its frame first and turns the outputs off only
    // after this pause, so the screen blackens visibly instead of vanishing
    // in the same frame.
    readonly property int lockBlackDelay: 300
    // The black stage keeps its frame full screen this long after the input
    // that turns the outputs back on, so the contraction into the notch plays
    // over a lit panel instead of finishing while it is still waking.
    readonly property int lockWakeDelay: 1000
    // Give up waiting for the outputs and contract anyway after this long.
    readonly property int lockWakeTimeout: 5000
    // How often the lock asks the compositor whether the outputs are back.
    readonly property int lockWakePoll: 150
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
    // The notch holds the install confirmation this long before it closes.
    readonly property int webappConfirm: 1200

    // Unread dot blink half-period (milliseconds).
    readonly property int blink: Motion.blink

    // Polling (milliseconds)
    readonly property int sysPoll: 2000
    // Uptime refresh; the control center shows whole minutes.
    readonly property int uptimePoll: 30000

    // Wait before restarting a cava that exited while a player is playing.
    readonly property int cavaRestart: 2000

    // Animation durations (milliseconds)
    readonly property int animFast: Motion.animFast
    readonly property int animNormal: Motion.animNormal
    readonly property int animSlow: Motion.animSlow
}

pragma Singleton

import Quickshell
import Quickshell.Io
import "../config"
import "../logic/lockStage.mjs" as LockStage

// The only contract through which lock requests and lock state reach the shell.
Singleton {
    id: root

    // Fired once per request; does not change `locked`.
    signal lockRequested

    // What the lock shows once it is up: "normal", or the idle stages
    // "screensaver" (wallpaper and padlock) and "black" (nothing at all).
    readonly property string stage: privateStage
    property string privateStage: "normal"

    // Changes only through setLocked (tests and stubs until the lock module lands).
    readonly property bool locked: privateLocked
    property bool privateLocked: false

    // true once the compositor confirms the session lock (written by the lock).
    readonly property bool secure: privateSecure
    property bool privateSecure: false

    function setSecure(value: bool) {
        privateSecure = value;
    }

    function requestLock() {
        privateStage = "normal";
        lockRequested();
    }

    // The screensaver stage of the idle chain: lock as usual, but show only
    // the wallpaper and the padlock until an input.
    function requestIdleLock() {
        privateStage = "screensaver";
        lockRequested();
    }

    // The lock minutes are over: darken a locked session, or lock it the
    // usual way when the screensaver minutes were off.
    function beginBlack() {
        privateStage = LockStage.idleStageAction(privateLocked) === "black" ? "black" : "normal";
        if (privateStage === "normal")
            lockRequested();
    }

    // Any input ends a screensaver or black stage: the lock form takes over.
    function endStage() {
        privateStage = "normal";
    }

    function setLocked(value: bool) {
        privateLocked = value;
    }

    // `qs -c notch ipc call lock lock`: keybinds and the sleep hook.
    LazyLoader {
        active: !Flags.smoke

        IpcHandler {
            target: "lock"

            function lock(): void {
                root.requestLock();
            }
        }
    }
}

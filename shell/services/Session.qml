pragma Singleton

import Quickshell
import Quickshell.Io
import "../config"

// The only contract through which lock requests and lock state reach the shell.
Singleton {
    id: root

    // Fired once per request; does not change `locked`.
    signal lockRequested

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
        lockRequested();
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

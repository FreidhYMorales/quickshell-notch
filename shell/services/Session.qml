pragma Singleton

import Quickshell

// The only contract through which lock requests and lock state reach the shell.
Singleton {
    id: root

    // Fired once per request; does not change `locked`.
    signal lockRequested

    // Changes only through setLocked (tests and stubs until the lock module lands).
    readonly property bool locked: privateLocked
    property bool privateLocked: false

    function requestLock() {
        lockRequested();
    }

    function setLocked(value: bool) {
        privateLocked = value;
    }
}

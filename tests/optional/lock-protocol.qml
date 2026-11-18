import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            color: "black"
        }
        onSecureChanged: if (secure) {
            console.log("isolated: secure");
            lock.locked = false;
            finish.start();
        }
    }

    Timer {
        interval: 150
        running: true
        onTriggered: lock.locked = true
    }

    Timer {
        id: finish
        interval: 100
        onTriggered: Qt.exit(0)
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: Qt.exit(2)
    }
}

import QtQuick
import Quickshell

// Loads the real lock component without locking anything. It must register one
// idle capture host per screen and never start a capture on its own.
ShellRoot {
    id: root
    property var lock: null

    Component.onCompleted: {
        root.lock = Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; Lock {}', root);
        check.start();
    }

    Timer {
        id: check
        interval: 400
        onTriggered: {
            const names = Object.keys(root.lock.frames);
            if (names.length !== Quickshell.screens.length)
                return Qt.exit(2);
            const first = Quickshell.screens[0].name;
            if (root.lock.frameFor(first) === null)
                return Qt.exit(6);
            for (const name of names) {
                if (root.lock.frames[name].active)
                    return Qt.exit(3);
            }
            if (root.lock.frameFor("not-a-screen") !== null)
                return Qt.exit(4);
            console.log("lock load: " + names.length + " idle capture host(s): " + names.join(", "));
            Qt.exit(0);
        }
    }
    Timer {
        interval: 6000
        running: true
        onTriggered: Qt.exit(5)
    }
}

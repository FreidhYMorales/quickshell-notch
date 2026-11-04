pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/sleepLock.mjs" as SleepLogic

// Locks the session before every sleep. Holds a logind delay inhibitor and
// watches PrepareForSleep, which logind sends before it freezes user
// processes; the inhibitor is released once the compositor confirms the lock.
// A system-sleep hook cannot do this: systemd freezes user.slice first.
Singleton {
    id: root

    property var state: ({
            sleeping: false,
            locked: Session.secure
        })
    property bool inhibit: true

    function dispatch(event: var) {
        const next = SleepLogic.sleepStep(root.state, event);
        root.state = {
            sleeping: next.sleeping,
            locked: next.locked
        };
        root.inhibit = next.inhibit;
        if (next.requestLock)
            Session.requestLock();
    }

    Connections {
        function onSecureChanged() {
            root.dispatch({
                type: "Locked",
                on: Session.secure
            });
        }

        target: Session
    }

    Process {
        running: !Flags.smoke
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                const on = SleepLogic.parseSleepSignal(line);
                if (on !== null)
                    root.dispatch({
                        type: "PrepareForSleep",
                        on: on
                    });
            }
        }
        onExited: code => console.warn("SleepLock: logind monitor exited with " + code)
    }

    Process {
        running: !Flags.smoke && root.inhibit
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=notch", "--why=" + Strings.sleepInhibitReason, "sleep", "infinity"]
    }
}

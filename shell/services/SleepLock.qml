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
    property bool monitorHealthy: false
    property int monitorFailures: 0
    property int stateCheckFailures: 0

    function checkMonitorState() {
        monitorState.running = true;
    }

    function retryMonitorStateCheck() {
        stateCheckFailures++;
        stateCheckRetry.interval = SleepLogic.monitorRetryDelay(stateCheckFailures);
        stateCheckRetry.restart();
    }

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
        id: monitor

        running: !Flags.smoke
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("Monitoring signals on object") >= 0) {
                    root.checkMonitorState();
                    return;
                }
                const on = SleepLogic.parseSleepSignal(line);
                if (on !== null)
                    root.dispatch({
                        type: "PrepareForSleep",
                        on: on
                    });
            }
        }
        onExited: code => {
            monitor.running = false;
            root.monitorHealthy = false;
            root.monitorFailures++;
            retry.interval = SleepLogic.monitorRetryDelay(root.monitorFailures);
            retry.restart();
            console.warn("SleepLock: logind monitor exited with " + code + "; retrying in " + retry.interval + " ms");
        }
    }

    Timer {
        id: retry

        repeat: false
        onTriggered: monitor.running = true
    }

    Timer {
        id: stateCheckRetry

        repeat: false
        onTriggered: monitorState.running = true
    }

    Process {
        id: monitorState

        command: ["gdbus", "call", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1", "--method", "org.freedesktop.DBus.Properties.Get", "org.freedesktop.login1.Manager", "PreparingForSleep"]
        stdout: SplitParser {
            onRead: line => {
                const sleeping = SleepLogic.parsePreparingForSleep(line);
                if (sleeping === null) {
                    root.monitorHealthy = false;
                    root.retryMonitorStateCheck();
                    console.warn("SleepLock: could not verify logind sleep state; keeping sleep blocked");
                    return;
                }
                if (sleeping)
                    root.dispatch({
                        type: "PrepareForSleep",
                        on: true
                    });
                root.monitorFailures = 0;
                root.stateCheckFailures = 0;
                root.monitorHealthy = true;
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.monitorHealthy = false;
                root.retryMonitorStateCheck();
                console.warn("SleepLock: could not query logind sleep state; keeping sleep blocked");
            }
        }
    }

    Process {
        running: !Flags.smoke && root.inhibit
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=notch", "--why=" + Strings.sleepInhibitReason, "sleep", "infinity"]
    }

    Process {
        running: !Flags.smoke && !root.monitorHealthy
        command: ["systemd-inhibit", "--what=sleep", "--mode=block", "--who=notch", "--why=SleepLock monitor unavailable", "sleep", "infinity"]
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"
import "../logic/lockSecurity.mjs" as LockSecurity

// The session lock: one surface per monitor, one shared authentication.
// Locks on Session.lockRequested and is the only writer of Session.locked.
// Never created under Flags.smoke.
Scope {
    id: root

    LockPam {
        id: sharedAuth

        fingerprintEnabled: LockSecurity.fingerprintEnabled(notchSecurity.loaded ? notchSecurity.text() : null, oldSecurity.loaded ? oldSecurity.text() : null)
        onUnlocked: lock.locked = false
    }

    // Read-only: this story never writes either file.
    FileView {
        id: notchSecurity

        path: Wallpapers.notchDir + "/security.json"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: oldSecurity

        path: Wallpapers.oldDir + "/security.json"
        blockLoading: true
        printErrors: false
    }

    Connections {
        function onLockRequested() {
            lock.locked = true;
        }

        target: Session
    }

    WlSessionLock {
        id: lock

        onLockedChanged: {
            Session.setLocked(locked);
            if (locked)
                sharedAuth.listen();
            else
                sharedAuth.stop();
        }

        WlSessionLockSurface {
            id: surface

            color: Colours.background

            Image {
                readonly property string path: surface.screen ? Wallpapers.pathFor(surface.screen.name) : ""

                anchors.fill: parent
                source: path === "" ? "" : "file://" + path
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                onStatusChanged: {
                    if (status === Image.Error)
                        console.warn("Lock: cannot load wallpaper " + path);
                }
            }

            LockContent {
                anchors.fill: parent
                // Not `auth: auth`: inside LockContent that name is its own property.
                auth: sharedAuth
                screen: surface.screen
            }
        }
    }
}

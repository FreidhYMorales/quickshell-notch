import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"
import "../notches/center"
import "../logic/earGeometry.mjs" as EarGeometry
import "../logic/lockSecurity.mjs" as LockSecurity

// The compositor keeps every monitor covered by WlSessionLockSurface for the
// entire morph. Only successful PAM authentication may begin the exit.
Scope {
    id: root

    property real reveal: 1
    property bool exiting: false
    property real blurAmount: 0
    readonly property int morphDuration: 520

    function startExit() {
        if (!lock.locked || root.exiting)
            return;
        root.exiting = true;
        exitMorph.restart();
    }

    LockPam {
        id: sharedAuth
        fingerprintEnabled: LockSecurity.fingerprintEnabled(notchSecurity.loaded ? notchSecurity.text() : null, oldSecurity.loaded ? oldSecurity.text() : null)
        onUnlocked: root.startExit()
    }

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
        target: Session
        function onLockRequested() {
            if (lock.locked)
                return;
            exitMorph.stop();
            root.exiting = false;
            root.reveal = 0;
            root.blurAmount = 1;
            lock.locked = true;
            enterMorph.restart();
        }
    }

    NumberAnimation {
        id: enterMorph
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
    }

    NumberAnimation {
        id: exitMorph
        target: root
        property: "reveal"
        from: 1
        to: 0
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
        onFinished: {
            // Never release a session lock before PAM has succeeded.
            if (root.exiting && lock.locked)
                lock.locked = false;
        }
    }

    WlSessionLock {
        id: lock

        onLockedChanged: {
            Session.setLocked(locked);
            if (locked)
                sharedAuth.listen();
            else {
                enterMorph.stop();
                exitMorph.stop();
                sharedAuth.stop();
                root.exiting = false;
                root.reveal = 1;
                root.blurAmount = 0;
            }
        }
        onSecureChanged: Session.setSecure(secure)

        WlSessionLockSurface {
            id: surface
            color: Colours.background

            // Always cover the compositor while locked. The wallpaper is a
            // safe, static backdrop; the morph itself is a visible Shape,
            // not a texture mask (which could turn the notch invisible).
            readonly property string wallpaperPath: surface.screen ? Wallpapers.pathFor(surface.screen.name) : ""
            readonly property real idleWidth: Math.max(80, CenterStore.idleNotchWidths[surface.screen?.name] || 300)
            readonly property real morphWidth: idleWidth + (width - idleWidth) * root.reveal
            readonly property real morphHeight: Layout.idleHeight + (height - Layout.idleHeight) * root.reveal
            readonly property real ear: Layout.earRadius * (1 - root.reveal)
            readonly property real corner: Layout.cornerRadius * (1 - root.reveal)

            Image {
                anchors.fill: parent
                source: surface.wallpaperPath === "" ? "" : "file://" + surface.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 32
                    blur: root.blurAmount
                }
            }

            Shape {
                id: morph
                width: surface.morphWidth
                height: surface.morphHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: -1
                    fillColor: Colours.background
                    PathSvg {
                        path: EarGeometry.notchPath(morph.width, morph.height, surface.ear, surface.corner)
                    }
                }
            }

            // Keep the authentication content in full-screen coordinates so
            // it does not jump when the animated notch changes its dimensions.
            LockContent {
                anchors.fill: parent
                auth: sharedAuth
                screen: surface.screen
                enabled: !root.exiting && root.reveal >= 0.98
                opacity: root.exiting ? Math.max(0, root.reveal * 2 - 1) : Math.max(0, root.reveal * 2 - 1)
            }
        }
    }
}

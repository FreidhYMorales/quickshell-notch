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
            root.blurAmount = 0;
            lock.locked = true;
            enterBlur.restart();
        }
    }

    // Blur the secure wallpaper first, then expand the notch. This never
    // exposes the compositor's actual desktop beneath the session lock.
    NumberAnimation {
        id: enterBlur
        target: root
        property: "blurAmount"
        from: 0
        to: 1
        duration: 260
        easing.type: Easing.OutCubic
        onFinished: enterMorph.restart()
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
                enterBlur.stop();
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

            // Keep the entire secure surface visually covered while the
            // foreground notch grows/shrinks. A transparent session lock
            // cannot safely reveal the real desktop before PAM succeeds.
            readonly property string wallpaperPath: surface.screen ? Wallpapers.pathFor(surface.screen.name) : ""

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

            // Per-monitor geometry: the actual idle width is supplied by the
            // live center notch, not a fixed SDDM calibration constant.
            readonly property real idleWidth: Math.max(80, CenterStore.idleNotchWidths[surface.screen?.name] || 300)
            readonly property real morphWidth: idleWidth + (width - idleWidth) * root.reveal
            readonly property real morphHeight: Layout.idleHeight + (height - Layout.idleHeight) * root.reveal
            readonly property real ear: Layout.earRadius * (1 - root.reveal)
            readonly property real corner: Layout.cornerRadius * (1 - root.reveal)

            Shape {
                id: maskShape
                x: 0
                width: surface.morphWidth
                height: surface.morphHeight
                visible: false
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: -1
                    fillColor: "#ffffff"
                    PathSvg {
                        path: EarGeometry.notchPath(maskShape.width, maskShape.height, surface.ear, surface.corner)
                    }
                }
                layer.enabled: true
            }

            Item {
                id: morph
                width: surface.morphWidth
                height: surface.morphHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                clip: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: maskShape
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                Item {
                    width: surface.width
                    height: surface.height
                    x: -morph.x

                    // Use the same wallpaper without an unrelated color tint.
                    // The full-screen background remains blurred underneath.
                    Image {
                        anchors.fill: parent
                        source: surface.wallpaperPath === "" ? "" : "file://" + surface.wallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    LockContent {
                        anchors.fill: parent
                        auth: sharedAuth
                        screen: surface.screen
                        enabled: !root.exiting
                        opacity: root.exiting ? Math.max(0, root.reveal * 2 - 1) : Math.min(1, root.reveal * 2)
                    }
                }
            }
        }
    }
}

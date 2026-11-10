import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import QtMultimedia
import "../../shell/logic/greetdPreview.mjs" as Flow
import "../../shell/logic/wallpaperState.mjs" as WallpaperState
import "../../shell/logic/earGeometry.mjs" as EarGeometry

// Isolated visual simulation, not a greeter and not connected to greetd or PAM.
Window {
    id: root
    visible: true
    width: 1280
    height: 720
    title: "greetd simulation — no authentication"
    color: "#141a23"
    property string stateName: "form"
    property bool simulateFailure: false
    // Visual tokens come from the launcher as
    // `-- notch-preview <background> <accent> <foreground> <notchWidth>`;
    // a `-` token keeps the built-in default.
    readonly property var previewArguments: {
        const all = Qt.application.arguments;
        const at = all.indexOf("notch-preview");
        return at < 0 ? [] : all.slice(at + 1, at + 5);
    }
    function previewColour(index, fallback) {
        const value = previewArguments[index];
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value || "") ? value : fallback;
    }
    function previewWidth(index, fallback) {
        const value = Number(previewArguments[index]);
        return isFinite(value) && value > 0 ? Math.max(80, value) : fallback;
    }
    property real notchWidth: previewWidth(3, 300)
    property color accent: previewColour(1, "#c6c6c6")
    property color foreground: previewColour(2, "#e4e4e4")
    readonly property real notchHeight: 32
    readonly property real earRadius: 12
    readonly property real cornerRadius: 18
    // Set only by the isolated Quickshell mock-protocol wrapper.
    property var protocolBackend: null
    signal protocolAnimationComplete
    signal protocolFailureComplete
    onClosing: if (protocolBackend)
        Qt.quit()
    property real reveal: 1
    property url background: protocolBackend ? "" : (previewArguments[0] && previewArguments[0] !== "-" ? previewArguments[0] : "")
    readonly property bool videoBackground: WallpaperState.isVideoPath(background.toString())

    function dispatch(event) {
        stateName = Flow.transition(stateName, event);
    }

    function submit(fail) {
        if (stateName !== "form" && stateName !== "error")
            return;
        if (stateName === "error")
            dispatch("edit");
        demoInput.text = "";
        root.contentItem.forceActiveFocus();
        simulateFailure = fail;
        dispatch("submit");
        if (protocolBackend)
            protocolBackend.begin(fail);
        else
            simulatedAuth.restart();
    }

    function completeMockAuthentication(failed) {
        if (stateName !== "authenticating")
            return;
        dispatch(failed ? "failure" : "success");
        exitMorph.restart();
    }

    AnimatedImage {
        anchors.fill: parent
        source: root.videoBackground ? "" : root.background
        visible: !root.videoBackground
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        playing: true
    }

    MediaPlayer {
        id: backgroundPlayer
        source: root.videoBackground ? root.background : ""
        videoOutput: backgroundVideo
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            muted: true
        }
        Component.onCompleted: if (root.videoBackground)
            play()
        onErrorOccurred: (error, message) => console.warn("Preview video: " + message)
    }
    VideoOutput {
        id: backgroundVideo
        objectName: "previewBackgroundVideo"
        anchors.fill: parent
        visible: root.videoBackground
        fillMode: VideoOutput.PreserveAspectCrop
    }

    Shape {
        id: morphMaskShape
        x: morph.x
        width: morph.width
        height: morph.height
        visible: false
        ShapePath {
            strokeWidth: -1
            fillColor: "white"
            PathSvg {
                path: EarGeometry.notchPath(morph.width, morph.height, root.earRadius * (1 - root.reveal), root.cornerRadius * (1 - root.reveal))
            }
        }
    }
    ShaderEffectSource {
        id: morphMaskTexture
        sourceItem: morphMaskShape
        hideSource: true
        live: true
        visible: false
    }

    Item {
        id: morph
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.notchWidth + (root.width - root.notchWidth) * root.reveal
        height: root.notchHeight + (root.height - root.notchHeight) * root.reveal
        clip: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: morphMaskTexture
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Rectangle {
            x: -morph.x
            width: root.width
            height: root.height
            color: "#a0000000"

            Column {
                anchors.centerIn: parent
                spacing: 18
                opacity: root.reveal
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "hh:mm")
                    font.pixelSize: 76
                    color: root.foreground
                }
                TextField {
                    id: demoInput
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 300
                    placeholderText: "Demo only — do not enter a real password"
                    echoMode: TextInput.Password
                    enabled: root.stateName === "form" || root.stateName === "error"
                    onActiveFocusChanged: if (activeFocus && root.stateName === "error")
                        root.dispatch("edit")
                    background: Rectangle {
                        radius: 20
                        color: "black"
                        border.width: root.stateName === "error" ? 2 : 0
                        border.color: "#ff7777"
                    }
                    color: root.foreground
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.stateName === "authenticating" ? "Authenticating (simulated)…" : (root.stateName === "error" ? "Incorrect password (simulated)" : "greetd preview — no real authentication")
                    color: root.stateName === "error" ? "#ff7777" : root.accent
                    font.pixelSize: 18
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    Button {
                        text: "Simulate success"
                        enabled: root.stateName === "form" || root.stateName === "error"
                        onClicked: root.submit(false)
                    }
                    Button {
                        text: "Simulate failure"
                        enabled: root.stateName === "form" || root.stateName === "error"
                        onClicked: root.submit(true)
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.protocolBackend ? "Private simulated socket; no real password, PAM or session launch." : "No password, PAM, greetd or session launch is used. Close this window to exit."
                    color: "#dddddd"
                    font.pixelSize: 13
                }
            }
        }
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.notchWidth
        height: root.notchHeight
        color: "transparent"
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: -1
                fillColor: "black"
                PathSvg {
                    path: EarGeometry.notchPath(root.notchWidth, root.notchHeight, root.earRadius, root.cornerRadius)
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: "󰌾"
            color: root.stateName === "shaking" || root.stateName === "error" ? "#ff7777" : root.foreground
            font.family: "IosevkaTerm Nerd Font"
            font.pixelSize: 18
            transform: Translate {
                id: lockOffset
            }
        }
    }
    Timer {
        id: simulatedAuth
        interval: 650
        onTriggered: {
            if (root.simulateFailure) {
                root.completeMockAuthentication(true);
            } else {
                root.completeMockAuthentication(false);
            }
        }
    }
    NumberAnimation {
        id: exitMorph
        target: root
        property: "reveal"
        from: 1
        to: 0
        duration: 520
        easing.type: Easing.InOutCubic
        onFinished: {
            const failed = root.stateName === "rejecting";
            root.dispatch("finished");
            if (failed)
                failureShake.restart();
            else {
                if (root.protocolBackend)
                    root.protocolAnimationComplete();
                resetTimer.restart();
            }
        }
    }
    SequentialAnimation {
        id: failureShake
        NumberAnimation {
            target: lockOffset
            property: "x"
            to: -6
            duration: 60
        }
        NumberAnimation {
            target: lockOffset
            property: "x"
            to: 6
            duration: 120
        }
        NumberAnimation {
            target: lockOffset
            property: "x"
            to: -4
            duration: 100
        }
        NumberAnimation {
            target: lockOffset
            property: "x"
            to: 0
            duration: 80
        }
        onFinished: {
            root.dispatch("finished");
            returnMorph.restart();
        }
    }
    Timer {
        id: resetTimer
        interval: 1100
        onTriggered: {
            root.dispatch("reset");
            returnMorph.restart();
        }
    }
    NumberAnimation {
        id: returnMorph
        target: root
        property: "reveal"
        to: 1
        duration: 520
        easing.type: Easing.InOutCubic
        onFinished: if (root.protocolBackend && root.stateName === "error")
            root.protocolFailureComplete()
    }
}

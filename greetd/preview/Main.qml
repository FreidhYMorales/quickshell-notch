import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import QtMultimedia
import "../../shell/logic/greetdPreview.mjs" as Flow
import "../../shell/logic/wallpaperState.mjs" as WallpaperState
import "../../shell/logic/earGeometry.mjs" as EarGeometry

// Notch login surface shared by the isolated simulation (demo: true) and a
// real greetd session (demo: false). Credentials only exist in real mode.
Window {
    id: root
    visible: true
    width: 1280
    height: 720
    title: demo ? "greetd simulation — no authentication" : "notch login"
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
    // Set by the entrypoint: true for the isolated simulation, false for a
    // real greetd session.
    property bool demo: true
    property var users: []
    property string username: ""
    property bool choosingUser: false
    // A visible PAM prompt awaits typed text instead of the password.
    property bool awaitingPrompt: false
    property bool promptSecret: false
    onAwaitingPromptChanged: {
        if (!demo && awaitingPrompt && stateName === "authenticating") {
            exitMorph.stop();
            returnMorph.restart();
        }
    }
    property int authTimeoutMs: 20000
    property bool authTimedOut: false
    property string protocolMessage: ""
    property string failureText: ""
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

    function startAuthentication() {
        if (stateName !== "form" && stateName !== "error")
            return false;
        if (stateName === "error")
            dispatch("edit");
        passwordInput.text = "";
        root.contentItem.forceActiveFocus();
        protocolMessage = "";
        failureText = "";
        authTimedOut = false;
        dispatch("submit");
        if (!demo) {
            authDeadline.restart();
            returnMorph.stop();
            exitMorph.restart();
        }
        return true;
    }

    // The simulation keeps its two buttons and fixed user/secret.
    function submitDemo(fail) {
        if (!startAuthentication())
            return;
        simulateFailure = fail;
        if (protocolBackend)
            protocolBackend.begin(fail ? "preview-failure" : "preview-user", "fake-test-secret");
        else
            simulatedAuth.restart();
    }

    // Real credentials. Never logged, stored or reused after the attempt.
    function submit(user, password) {
        if (!user || !password || !protocolBackend)
            return;
        if (!startAuthentication())
            return;
        protocolBackend.begin(user, password);
    }

    function submitEntered() {
        if (awaitingPrompt) {
            const text = passwordInput.text;
            if (text.length === 0) {
                inputShake.restart();
                return;
            }
            awaitingPrompt = false;
            passwordInput.text = "";
            if (!demo && !authTimedOut) {
                returnMorph.stop();
                exitMorph.restart();
            }
            protocolBackend.respond(text);
            return;
        }
        if (stateName !== "form" && stateName !== "error")
            return;
        if (passwordInput.text.length === 0) {
            inputShake.restart();
            return;
        }
        submit(username, passwordInput.text);
    }

    function completeAuthentication(failed) {
        if (stateName !== "authenticating")
            return;
        authDeadline.stop();
        authTimedOut = false;
        dispatch(failed ? "failure" : "success");
        if (demo) {
            exitMorph.restart();
        } else if (reveal <= 0.001 && !returnMorph.running) {
            finishCompression();
        } else if (!exitMorph.running) {
            returnMorph.stop();
            exitMorph.restart();
        }
    }

    function finishCompression() {
        if (stateName === "rejecting") {
            dispatch("finished");
            failureShake.restart();
        } else if (stateName === "animating") {
            dispatch("finished");
            if (protocolBackend)
                protocolAnimationComplete();
            resetTimer.restart();
        }
    }

    function displayName() {
        for (const user of users) {
            if (user.name === username)
                return user.displayName;
        }
        return username;
    }

    function statusText() {
        if (stateName === "authenticating" && awaitingPrompt && protocolMessage !== "")
            return protocolMessage;
        if (stateName === "authenticating" && authTimedOut)
            return "Authentication pending…";
        if (stateName === "authenticating")
            return demo ? "Authenticating (simulated)…" : "Authenticating…";
        if (stateName === "error") {
            if (failureText !== "")
                return failureText;
            return demo ? "Incorrect password (simulated)" : "Incorrect password";
        }
        if (protocolMessage !== "")
            return protocolMessage;
        return demo ? "greetd preview — no real authentication" : "";
    }

    Timer {
        id: authDeadline
        interval: root.authTimeoutMs
        onTriggered: if (root.stateName === "authenticating") {
            root.authTimedOut = true;
            exitMorph.stop();
            returnMorph.restart();
        }
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
                spacing: 14
                opacity: root.reveal
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "hh:mm")
                    font.pixelSize: 76
                    color: root.foreground
                }
                // Real mode: current account, clickable when there is a choice.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(chipRow.width, 160)
                    height: 56
                    visible: !root.demo && root.users.length > 0
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 10
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: "#303946"
                            Text {
                                anchors.centerIn: parent
                                text: root.username.length > 0 ? root.username[0].toUpperCase() : "?"
                                color: root.foreground
                                font.pixelSize: 18
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: root.displayName()
                                color: root.foreground
                                font.pixelSize: 16
                            }
                            Text {
                                visible: root.users.length > 1
                                text: "cambiar usuario"
                                color: root.accent
                                font.pixelSize: 11
                            }
                        }
                    }
                    TapHandler {
                        enabled: root.users.length > 1
                        onTapped: root.choosingUser = !root.choosingUser
                    }
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    visible: !root.demo && root.choosingUser && root.users.length > 1
                    Repeater {
                        model: root.users
                        delegate: Rectangle {
                            width: 200
                            height: 30
                            radius: 15
                            color: modelData.name === root.username ? "#22ffffff" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.displayName
                                color: root.foreground
                                font.pixelSize: 14
                            }
                            TapHandler {
                                onTapped: {
                                    root.username = modelData.name;
                                    root.choosingUser = false;
                                    passwordInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    TextField {
                        id: passwordInput
                        width: 280
                        placeholderText: root.demo ? "Demo only — do not enter a real password" : (root.awaitingPrompt ? "Respuesta" : (root.stateName === "authenticating" ? root.statusText() : "Contraseña"))
                        echoMode: root.awaitingPrompt && !root.promptSecret ? TextInput.Normal : TextInput.Password
                        enabled: root.stateName === "form" || root.stateName === "error" || root.awaitingPrompt
                        onActiveFocusChanged: if (activeFocus && root.stateName === "error")
                            root.dispatch("edit")
                        onAccepted: root.submitEntered()
                        background: Rectangle {
                            radius: 20
                            color: "black"
                            border.width: root.stateName === "error" ? 2 : 0
                            border.color: "#ff7777"
                        }
                        color: root.foreground
                        transform: Translate {
                            id: inputOffset
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.demo
                        text: "→"
                        color: root.accent
                        font.pixelSize: 25
                        TapHandler {
                            onTapped: root.submitEntered()
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 360
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.statusText()
                    visible: root.demo || root.stateName !== "authenticating" || root.awaitingPrompt
                    color: root.stateName === "error" ? "#ff7777" : root.accent
                    font.pixelSize: 15
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    visible: root.demo
                    Button {
                        text: "Simulate success"
                        enabled: root.stateName === "form" || root.stateName === "error"
                        onClicked: root.submitDemo(false)
                    }
                    Button {
                        text: "Simulate failure"
                        enabled: root.stateName === "form" || root.stateName === "error"
                        onClicked: root.submitDemo(true)
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 420
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: root.demo
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
            SequentialAnimation on scale {
                running: !root.demo && root.stateName === "authenticating" && root.reveal < 0.05
                loops: Animation.Infinite
                NumberAnimation {
                    to: 1.12
                    duration: 700
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: 700
                    easing.type: Easing.InOutSine
                }
            }
            transform: Translate {
                id: lockOffset
            }
        }
    }
    Timer {
        id: simulatedAuth
        interval: 650
        onTriggered: root.completeAuthentication(root.simulateFailure)
    }
    SequentialAnimation {
        id: inputShake
        NumberAnimation {
            target: inputOffset
            property: "x"
            to: -4
            duration: 55
        }
        NumberAnimation {
            target: inputOffset
            property: "x"
            to: 4
            duration: 110
        }
        NumberAnimation {
            target: inputOffset
            property: "x"
            to: 0
            duration: 70
        }
    }
    NumberAnimation {
        id: exitMorph
        target: root
        property: "reveal"
        to: 0
        duration: 520
        easing.type: Easing.InOutCubic
        onFinished: {
            root.finishCompression();
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
        onFinished: {
            if (root.awaitingPrompt && root.stateName === "authenticating")
                passwordInput.forceActiveFocus();
            if (root.protocolBackend && root.stateName === "error")
                root.protocolFailureComplete();
        }
    }
}

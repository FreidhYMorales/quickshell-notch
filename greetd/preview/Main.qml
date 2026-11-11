import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.VirtualKeyboard
import QtMultimedia
import "../../shell/logic/greetdPreview.mjs" as Flow
import "../../shell/logic/wallpaperState.mjs" as WallpaperState
import "../../shell/logic/earGeometry.mjs" as EarGeometry
import "../../shell/logic/users.mjs" as Users

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
    property int simulatedDelayMs: 1600
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
    property bool parityPreview: Qt.application.arguments.indexOf("notch-parity-preview") !== -1
    readonly property bool realisticSurface: !demo || parityPreview
    readonly property alias compressionRunning: exitMorph.running
    readonly property alias morphWidth: morph.width
    readonly property alias morphHeight: morph.height
    property string view: realisticSurface ? "clock" : "login"
    property real loginProgress: view === "login" ? 1 : 0
    Behavior on loginProgress {
        NumberAnimation {
            duration: 440
            easing.type: Easing.InOutCubic
        }
    }
    property date now: new Date()
    property var users: parityPreview ? [
        {
            name: "preview-user",
            displayName: "Usuario de prueba"
        },
        {
            name: "preview-guest",
            displayName: "Invitado"
        }
    ] : []
    readonly property alias accountAvatar: avatarCircle
    readonly property alias loginControls: loginControls
    readonly property alias passwordField: passwordInput
    readonly property alias lockGlyph: lockGlyph
    readonly property alias submitIcon: submitIcon
    readonly property alias sessionIcon: sessionIcon
    readonly property alias sessionSelector: sessions
    readonly property alias virtualKeyboardPanel: virtualKeyboard
    readonly property real clockPosition: clockGroup.y
    readonly property bool simulationButtonsVisible: simulationButtons.visible
    readonly property bool simulationArrowVisible: simulationArrow.visible
    readonly property bool footerPowerEnabled: !demo && footer.enabled
    property string username: parityPreview ? "preview-user" : ""
    property bool choosingUser: false
    property bool keyboardRequested: false
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

    function showLogin() {
        if (stateName !== "form" && stateName !== "error")
            return;
        view = "login";
        if (!demo)
            Qt.callLater(() => passwordInput.forceActiveFocus());
    }

    function showClock() {
        if (stateName !== "form" && stateName !== "error")
            return;
        choosingUser = false;
        if (keyboardRequested || Qt.inputMethod.visible)
            Qt.inputMethod.hide();
        keyboardRequested = false;
        view = "clock";
        clockKeys.forceActiveFocus();
    }

    function requestPower(action) {
        if (demo || stateName !== "form" && stateName !== "error")
            return;
        if ((action === "poweroff" || action === "reboot") && protocolBackend && typeof protocolBackend.power === "function")
            protocolBackend.power(action);
    }

    function toggleKeyboard() {
        if (demo && !parityPreview)
            return;
        keyboardRequested = !keyboardRequested;
        if (parityPreview)
            return;
        if (keyboardRequested) {
            passwordInput.forceActiveFocus();
            Qt.inputMethod.show();
        } else {
            Qt.inputMethod.hide();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function startAuthentication() {
        if (stateName !== "form" && stateName !== "error")
            return false;
        if (stateName === "error")
            dispatch("edit");
        passwordInput.text = "";
        if (keyboardRequested || Qt.inputMethod.visible)
            Qt.inputMethod.hide();
        keyboardRequested = false;
        root.contentItem.forceActiveFocus();
        protocolMessage = "";
        failureText = "";
        choosingUser = false;
        authTimedOut = false;
        dispatch("submit");
        if (realisticSurface) {
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
        if (demo || !user || !password || !protocolBackend)
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
        if (parityPreview)
            return;
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
        if (demo && !parityPreview) {
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

    function avatarSource() {
        return demo ? "" : Users.avatarUrl(username);
    }

    function chooseAccount(name) {
        if (stateName !== "form" && stateName !== "error")
            return;
        username = name;
        choosingUser = false;
        passwordInput.text = "";
        failureText = "";
        if (stateName === "error")
            dispatch("edit");
        passwordInput.forceActiveFocus();
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
            color: "#52000000"

            Item {
                id: clockGroup
                width: 600
                height: 190 - 70 * root.loginProgress
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.realisticSurface ? (root.height - 190) / 2 + (root.height * 0.25 - (root.height - 190) / 2) * root.loginProgress : (root.height - 190) / 2
                opacity: root.reveal
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    scale: root.realisticSurface ? 1 - 0.30 * root.loginProgress : 1
                    transformOrigin: Item.Center
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(root.now, "hh:mm")
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: root.realisticSurface ? 100 : 76
                        color: root.foreground
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.realisticSurface
                        text: Qt.formatDate(root.now, Qt.locale("es_GT"), "dddd, d MMMM yyyy")
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: 23
                        color: root.accent
                    }
                }
            }
            Column {
                id: loginPanel
                width: 284
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.realisticSurface ? root.height * (0.46 + 0.035 * (1 - root.loginProgress)) : root.height * 0.48
                spacing: 12
                opacity: root.reveal
                // Real mode: current account, clickable when there is a choice.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 284
                    height: 146
                    visible: root.realisticSurface && (root.view === "login" || root.loginProgress > 0) && root.users.length > 0
                    opacity: root.loginProgress
                    Rectangle {
                        id: avatarCircle
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 116
                        height: 116
                        radius: 58
                        color: "#303946"
                        clip: true
                        Image {
                            id: accountPhoto
                            anchors.fill: parent
                            anchors.margins: 8
                            source: root.avatarSource()
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                        Canvas {
                            anchors.centerIn: parent
                            width: 66
                            height: 66
                            visible: !accountPhoto.visible
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.fillStyle = root.foreground;
                                ctx.beginPath();
                                ctx.arc(33, 21, 10, 0, 2 * Math.PI);
                                ctx.fill();
                                ctx.beginPath();
                                ctx.moveTo(14, 56);
                                ctx.bezierCurveTo(14, 32, 52, 32, 52, 56);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                        TapHandler {
                            enabled: root.view === "login" && root.users.length > 1 && (root.stateName === "form" || root.stateName === "error")
                            onTapped: root.choosingUser = !root.choosingUser
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: avatarCircle.bottom
                        anchors.topMargin: 5
                        text: root.displayName()
                        color: root.foreground
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: 17
                    }
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    visible: root.realisticSurface && root.view === "login" && root.choosingUser && root.users.length > 1
                    opacity: root.loginProgress
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
                                enabled: root.stateName === "form" || root.stateName === "error"
                                onTapped: root.chooseAccount(modelData.name)
                            }
                        }
                    }
                }
                TextField {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 280
                    visible: root.realisticSurface && (root.view === "login" || root.loginProgress > 0) && root.users.length === 0
                    enabled: root.view === "login"
                    opacity: root.loginProgress
                    placeholderText: "Usuario"
                    text: root.username
                    onTextEdited: root.username = text
                    color: root.foreground
                }
                Rectangle {
                    id: loginControls
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 284
                    height: 40
                    radius: 20
                    color: "black"
                    border.width: root.stateName === "error" ? 2 : 0
                    border.color: "#ff7777"
                    visible: !root.realisticSurface || root.view === "login" || root.loginProgress > 0
                    enabled: !root.realisticSurface || root.view === "login"
                    opacity: root.realisticSurface ? root.loginProgress : 1
                    TextField {
                        id: passwordInput
                        anchors.left: parent.left
                        anchors.right: simulationArrow.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        leftPadding: 15
                        placeholderText: root.demo && !root.parityPreview ? "Solo simulación — no uses contraseñas" : (root.awaitingPrompt ? "Respuesta" : (root.stateName === "authenticating" ? root.statusText() : "Contraseña"))
                        echoMode: root.awaitingPrompt && !root.promptSecret ? TextInput.Normal : TextInput.Password
                        enabled: !root.parityPreview && (root.stateName === "form" || root.stateName === "error" || root.awaitingPrompt)
                        onActiveFocusChanged: if (activeFocus && root.stateName === "error")
                            root.dispatch("edit")
                        onAccepted: root.submitEntered()
                        background: Item {}
                        placeholderTextColor: "#a6b1bf"
                        color: root.foreground
                    }
                    Item {
                        id: simulationArrow
                        width: 40
                        height: 40
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.demo || root.parityPreview
                        Image {
                            id: submitIcon
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: "../../sddm/notch/icons/arrow-right.svg"
                            fillMode: Image.PreserveAspectFit
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: root.accent
                            }
                        }
                        TapHandler {
                            onTapped: {
                                if (root.parityPreview)
                                    root.submitDemo(false);
                                else
                                    root.submitEntered();
                            }
                        }
                    }
                    transform: Translate {
                        id: inputOffset
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 360
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.statusText()
                    visible: (!root.realisticSurface && root.demo) || (root.view === "login" && (root.stateName !== "authenticating" || root.awaitingPrompt))
                    color: root.stateName === "error" ? "#ff7777" : root.accent
                    font.pixelSize: 15
                }
                Row {
                    id: simulationButtons
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    visible: root.demo && !root.parityPreview
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
                    visible: root.demo && !root.parityPreview
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
            id: lockGlyph
            readonly property real pulseAmount: Math.max(0, Math.min(1, (scale - 1) / 0.12))
            anchors.centerIn: parent
            text: "󰌾"
            color: root.stateName === "shaking" || root.stateName === "error" ? "#ff7777" : Qt.rgba(root.foreground.r + (root.accent.r - root.foreground.r) * pulseAmount, root.foreground.g + (root.accent.g - root.foreground.g) * pulseAmount, root.foreground.b + (root.accent.b - root.foreground.b) * pulseAmount, 1)
            font.family: "IosevkaTerm Nerd Font"
            font.pixelSize: 18
            SequentialAnimation on scale {
                running: root.realisticSurface && root.stateName === "authenticating" && root.reveal < 0.05
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
    Item {
        id: clockKeys
        focus: root.realisticSurface && root.view === "clock"
        Keys.onPressed: event => {
            if (root.view === "clock") {
                root.showLogin();
                event.accepted = true;
            }
        }
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.realisticSurface && root.view === "login" && (root.stateName === "form" || root.stateName === "error")
        onActivated: root.showClock()
    }
    Shortcut {
        sequence: "Return"
        enabled: root.parityPreview && root.view === "login" && (root.stateName === "form" || root.stateName === "error")
        onActivated: root.submitDemo(false)
    }
    Shortcut {
        sequence: "Ctrl+Shift+F"
        enabled: root.parityPreview && root.view === "login" && (root.stateName === "form" || root.stateName === "error")
        onActivated: root.submitDemo(true)
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.realisticSurface && root.view === "clock" && (root.stateName === "form" || root.stateName === "error")
        onClicked: root.showLogin()
    }
    InputPanel {
        id: virtualKeyboard
        width: Math.min(root.width / 2, 600)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: footer.top
        anchors.bottomMargin: 12
        active: root.parityPreview ? root.keyboardRequested : Qt.inputMethod.visible
        visible: root.keyboardRequested && root.view === "login" && (!root.demo || root.parityPreview)
        layer.enabled: true
        layer.effect: ShaderEffect {
            property color darkColor: Qt.darker(root.accent, 4)
            property color lightColor: root.foreground
            property size panelSize: Qt.size(virtualKeyboard.width, virtualKeyboard.height)
            property real cornerRadius: 16
            fragmentShader: "../../sddm/notch/shaders/keyboard.frag.qsb"
        }
        z: 2
    }
    Row {
        id: footer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        z: 3
        opacity: root.loginProgress * root.reveal * (root.stateName === "authenticating" ? 0 : 1)
        visible: root.realisticSurface && opacity > 0
        enabled: root.view === "login" && (root.stateName === "form" || root.stateName === "error")
        ComboBox {
            id: sessions
            width: 190
            height: 34
            model: ["Hyprland"]
            currentIndex: 0
            font.pixelSize: 12
            background: Rectangle {
                radius: 17
                color: sessions.hovered || sessions.popup.visible ? "#303946" : "#cc000000"
                Behavior on color {
                    ColorAnimation {
                        duration: 160
                    }
                }
            }
            contentItem: Text {
                leftPadding: 14
                rightPadding: 26
                text: sessions.displayText
                color: "white"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            indicator: Item {
                width: 26
                height: parent.height
                x: parent.width - width - 4
                Image {
                    id: sessionIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "../../sddm/notch/icons/chevron-down.svg"
                    fillMode: Image.PreserveAspectFit
                    rotation: sessions.popup.visible ? 180 : 0
                    scale: sessions.hovered || sessions.popup.visible ? 1.2 : 1
                    Behavior on rotation {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.InOutCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }
            }
            delegate: ItemDelegate {
                required property int index
                required property string modelData
                width: ListView.view ? ListView.view.width : sessions.width - 2 * sessions.popup.padding
                highlighted: sessions.highlightedIndex === index
                contentItem: Text {
                    text: modelData
                    color: "white"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.highlighted ? "#303946" : "#171b22"
                    radius: Math.min(width, height) / 2
                }
            }
            popup: Popup {
                y: -implicitHeight - 6
                width: sessions.width
                padding: 5
                implicitHeight: contentItem.implicitHeight + 10
                contentItem: ListView {
                    implicitHeight: contentHeight
                    model: sessions.popup.visible ? sessions.delegateModel : null
                    currentIndex: sessions.highlightedIndex
                    clip: true
                }
                background: Rectangle {
                    color: "#171b22"
                    radius: 17
                }
            }
        }
        Repeater {
            model: [
                {
                    icon: "keyboard.svg",
                    hint: "Teclado virtual",
                    action: "keyboard"
                },
                {
                    icon: "chevron-left.svg",
                    hint: "Volver",
                    action: "back"
                },
                {
                    icon: "power.svg",
                    hint: "Apagar",
                    action: "poweroff"
                },
                {
                    icon: "rotate-ccw.svg",
                    hint: "Reiniciar",
                    action: "reboot"
                }
            ]
            delegate: Button {
                required property var modelData
                width: 36
                height: 34
                ToolTip.visible: hovered
                ToolTip.text: modelData.hint
                background: Rectangle {
                    radius: 17
                    color: parent.hovered || (modelData.action === "keyboard" && root.keyboardRequested) ? "#303946" : "#cc000000"
                }
                contentItem: Item {
                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: "../../sddm/notch/icons/" + modelData.icon
                        fillMode: Image.PreserveAspectFit
                    }
                }
                onClicked: {
                    if (modelData.action === "back")
                        root.showClock();
                    else if (modelData.action === "keyboard")
                        root.toggleKeyboard();
                    else
                        root.requestPower(modelData.action);
                }
            }
        }
    }
    Timer {
        id: simulatedAuth
        interval: root.parityPreview ? root.simulatedDelayMs : 650
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

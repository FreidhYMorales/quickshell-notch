import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.VirtualKeyboard
import QtMultimedia

Item {
    id: root
    width: 1280
    height: 720
    focus: true

    // Standalone theme. SDDM and Quickshell intentionally do not share auth.
    // Ctrl+Shift+Return previews the exit morph and restores the greeter.
    property string view: "clock"
    property bool exiting: false
    property bool previewingExit: false
    property bool authenticating: false
    property bool keyboardRequested: false
    property real reveal: 1
    // Matches the notch shell's lock morph so the two animations feel the same.
    readonly property int morphDuration: 520
    // How long the compressed notch frame is held before the demo expands.
    readonly property int previewHoldMs: 1100
    // Fingerprint PAM can take a few seconds; never leave the greeter compressed.
    readonly property int authTimeoutMs: 20000
    // --test-mode never has a daemon: sddm.login() cannot answer, so the greeter
    // replays the handoff and expands on its own instead of waiting for a signal.
    readonly property bool demoMode: Qt.application.arguments.indexOf("--test-mode") !== -1
    property date now: new Date()
    property string errorMessage: ""
    // The greeter has no access to Quickshell's singleton. A deployed
    // theme.conf.user can supply the palette copied by the sync integration.
    readonly property color accent: config.accent || "#c6c6c6"
    readonly property color foreground: config.foreground || "#e4e4e4"
    readonly property color panel: "#000000"
    readonly property bool videoBackground: config.mediaKind === "video"
    readonly property bool hasUsers: userModel.count > 0
    property int selectedUser: Math.max(0, userModel.lastIndex)
    property bool choosingUser: false
    readonly property string userName: hasUsers ? String(userModel.data(userModel.index(selectedUser, 0), 257) || "") : username.text
    readonly property string displayName: hasUsers ? String(userModel.data(userModel.index(selectedUser, 0), 258) || userName) : username.text
    readonly property string avatarPath: hasUsers ? String(userModel.data(userModel.index(selectedUser, 0), 260) || "") : ""
    // Two handoff presets. The actual idle width is content-driven in
    // CenterSurface.qml: idleWidth(baseWidth, sideNeed, batteryLayer, dotExtent).
    // These values are calibration targets, not runtime measurements.
    readonly property real normalNotchWidth: Math.max(80, Number(config.normalNotchWidth) || 300)
    readonly property real chargingNotchWidth: Math.max(normalNotchWidth, Number(config.chargingNotchWidth) || 420)
    readonly property real lowBatteryNotchWidth: Math.max(normalNotchWidth, Number(config.lowBatteryNotchWidth) || 420)
    readonly property string notchMode: String(config.notchMode || "normal")
    readonly property real notchWidth: notchMode === "charging" ? chargingNotchWidth : (notchMode === "low" ? lowBatteryNotchWidth : normalNotchWidth)
    readonly property real notchHeight: 32
    readonly property real earRadius: 12
    readonly property real cornerRadius: 18
    property real loginProgress: 0
    Behavior on loginProgress { NumberAnimation { duration: 440; easing.type: Easing.InOutCubic } }
    onLoginVisibleChanged: {
        loginProgress = loginVisible ? 1 : 0;
        if (!loginVisible) {
            keyboardRequested = false;
            Qt.inputMethod.hide();
        }
    }
    function notchPath(w, h, progress) {
        const t = progress === undefined ? 1 : Math.max(0, Math.min(1, progress));
        const e = Math.min(earRadius * t, h, w / 2);
        const corner = Math.max(0, Math.min(cornerRadius * t, h - e, w / 2 - e));
        const k = 0.5523 * e;
        return `M 0 0 L ${w} 0 C ${w-k} 0 ${w-e} ${e-k} ${w-e} ${e} L ${w-e} ${h-corner} A ${corner} ${corner} 0 0 1 ${w-e-corner} ${h} L ${e+corner} ${h} A ${corner} ${corner} 0 0 1 ${e} ${h-corner} L ${e} ${e} C ${e} ${e-k} ${k} 0 0 0 Z`;
    }
    readonly property bool loginVisible: view === "login"

    function chooseUser(index) {
        selectedUser = index;
        choosingUser = false;
        password.text = "";
        errorMessage = "";
        Qt.callLater(() => password.forceActiveFocus());
    }

    function showLogin() {
        if (exiting)
            return;
        view = "login";
        Qt.callLater(() => password.forceActiveFocus());
    }

    function submit() {
        if (exiting || authenticating || password.text.length === 0)
            return;
        errorMessage = "";
        keyboardRequested = false;
        Qt.inputMethod.hide();
        // SDDM stops the greeter shortly after authentication succeeds, so the
        // compression has to run before authenticating; see exitMorph.onFinished.
        authenticating = true;
        exiting = true;
        exitMorph.restart();
    }

    // A rejected password, a missed fingerprint or a silent PAM all return to
    // the login form; the compressed state is never a dead end.
    function recover(message) {
        authTimeout.stop();
        previewReset.stop();
        authenticating = false;
        previewingExit = false;
        exiting = false;
        errorMessage = message;
        password.text = "";
        returnMorph.restart();
        showLogin();
    }

    function previewExit() {
        if (exiting)
            return;
        previewingExit = true;
        exiting = true;
        exitMorph.restart();
    }

    function resetPreview() {
        if (!previewingExit)
            return;
        previewingExit = false;
        exiting = false;
        returnMorph.restart();
        root.forceActiveFocus();
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.recover("No se pudo iniciar sesión");
        }
        function onLoginSucceeded() {
            authTimeout.stop();
            root.previewingExit = false;
            if (root.authenticating) {
                // The greeter is already compressed; SDDM stops it in a few
                // milliseconds, so there is nothing left to animate.
                root.authenticating = false;
                return;
            }
            // Unexpected success (for example after the timeout): at least end
            // on the notch frame instead of the login form.
            root.exiting = true;
            root.reveal = 0;
        }
    }

    Timer {
        id: authTimeout
        interval: root.authTimeoutMs
        repeat: false
        onTriggered: root.recover("Tiempo de espera agotado")
    }

    Timer {
        id: previewReset
        interval: root.previewHoldMs
        repeat: false
        onTriggered: root.resetPreview()
    }

    Timer {
        id: demoReturn
        interval: root.previewHoldMs
        repeat: false
        onTriggered: root.recover("")
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
            if (root.previewingExit) {
                previewReset.restart();
                return;
            }
            if (root.demoMode) {
                // No daemon in test mode: hold the notch frame like the real
                // handoff, then expand so the recovery animation is visible.
                demoReturn.restart();
                return;
            }
            if (!root.authenticating)
                return;
            // Authenticate only now: SDDM kills the greeter ~74 ms after a
            // successful login, too soon for this animation to be seen.
            authTimeout.restart();
            sddm.login(hasUsers ? userName : username.text,
                       password.text, sessions.currentIndex);
        }
    }

    NumberAnimation {
        id: returnMorph
        target: root
        property: "reveal"
        // No from: start wherever the exit morph left reveal, so an early
        // failure expands smoothly instead of snapping back to 0 first.
        to: 1
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
    }

    Rectangle {
        anchors.fill: parent
        color: "#141a23"
    }

    // The compression reveals this undimmed wallpaper, so the last greeter
    // frame matches the notch shell's first frame. Video keeps the dark fill
    // because the one player lives inside the morph.
    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.videoBackground && status === Image.Ready
    }

    // Alpha mask follows the same concave-ear geometry as Quickshell.
    // At full reveal the radii are zero (full-screen rectangle); at the
    // end they become the exact configured notch radii.
    Shape {
        id: morphMaskShape
        x: morph.x
        y: 0
        width: morph.width
        height: morph.height
        visible: false
        ShapePath {
            strokeWidth: -1
            fillColor: "#ffffff"
            PathSvg {
                path: root.notchPath(morph.width, morph.height, 1 - root.reveal)
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
        width: root.notchWidth + (root.width - root.notchWidth) * root.reveal
        height: root.notchHeight + (root.height - root.notchHeight) * root.reveal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        clip: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: morphMaskTexture
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // The login UI lives inside the morph; compressing it into the notch
        // before authentication leaves the shell's wallpaper and notch on
        // screen when SDDM stops the greeter.
        Rectangle {
            width: root.width
            height: root.height
            x: -morph.x
            color: "#141a23"

            Image {
                anchors.fill: parent
                source: config.background
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: !root.videoBackground && status === Image.Ready
            }

            MediaPlayer {
                id: backgroundPlayer
                source: root.videoBackground ? config.background : ""
                videoOutput: backgroundVideo
                loops: MediaPlayer.Infinite
                audioOutput: AudioOutput { muted: true }
                Component.onCompleted: if (root.videoBackground) play()
                onErrorOccurred: (error, message) => console.warn("SDDM background: " + message)
            }

            VideoOutput {
                id: backgroundVideo
                anchors.fill: parent
                visible: root.videoBackground
                fillMode: VideoOutput.PreserveAspectCrop
            }

            Rectangle {
                anchors.fill: parent
                color: "#52000000"
            }

            Item {
                id: clockGroup
                width: 600
                height: 190 - 70 * root.loginProgress
                anchors.horizontalCenter: parent.horizontalCenter
                y: (root.height - 190) / 2 + (root.height * 0.22 - (root.height - 190) / 2) * root.loginProgress
                opacity: root.reveal


                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    scale: 1 - 0.30 * root.loginProgress
                    transformOrigin: Item.Center
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(root.now, "hh:mm")
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: 100
                        color: root.foreground
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
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
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.height * (0.46 + 0.035 * (1 - root.loginProgress))
                opacity: root.loginProgress * root.reveal
                visible: opacity > 0


                Item {
                    width: parent.width
                    height: root.choosingUser && root.hasUsers ? 184 : 146
                    Behavior on height { NumberAnimation { duration: 220 } }

                    Rectangle {
                        id: avatarCircle
                        width: 116
                        height: 116
                        radius: 58
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#303946"
                        clip: true

                        Image {
                            id: face
                            anchors.fill: parent
                            anchors.margins: 8
                            // The SDDM default icon is a dark oversized silhouette;
                            // render our own compact fallback instead.
                            source: root.avatarPath === "" || /default|face\.icon|avatar-default|user-default/i.test(root.avatarPath) ? "" : (root.avatarPath.indexOf(":/") >= 0 ? root.avatarPath : "file://" + root.avatarPath)
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            asynchronous: true
                        }
                        // Vector fallback avoids the optical offset of Nerd Font glyphs.
                        Canvas {
                            anchors.centerIn: parent
                            width: 66
                            height: 66
                            visible: !face.visible
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
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.hasUsers && userModel.count > 1
                            onClicked: root.choosingUser = !root.choosingUser
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: avatarCircle.bottom
                        anchors.topMargin: 5
                        text: root.displayName
                        color: root.foreground
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: 17
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: avatarCircle.bottom
                        anchors.topMargin: 34
                        visible: root.choosingUser && root.hasUsers
                        spacing: 10

                        Repeater {
                            model: userModel
                            delegate: Item {
                                width: 38
                                height: 38
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "#202630"
                                    border.width: index === root.selectedUser ? 2 : 0
                                    border.color: root.accent
                                    clip: true
                                    Image {
                                        id: optionFace
                                        anchors.fill: parent
                                        source: model.icon || ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: status === Image.Ready
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: !optionFace.visible
                                        text: "󰀄"
                                        font.family: "IosevkaTerm Nerd Font"
                                        font.pixelSize: 19
                                        color: "white"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.chooseUser(index)
                                    }
                                }
                            }
                        }
                    }
                }

                TextField {
                    id: username
                    visible: !root.hasUsers
                    width: parent.width
                    height: 44
                    placeholderText: "Usuario"
                    color: "white"
                    placeholderTextColor: "#9da8b7"
                    background: Rectangle { color: "#000000"; radius: 22 }
                    onAccepted: password.forceActiveFocus()
                }

                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 20
                    color: "#000000"

                    TextField {
                        id: password
                        anchors.left: parent.left
                        anchors.right: submitArrow.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        leftPadding: 15
                        background: Item {}
                        color: root.foreground
                        placeholderTextColor: "#a6b1bf"
                        placeholderText: "Contraseña"
                        echoMode: TextInput.Password
                        onAccepted: root.submit()
                    }
                    Item {
                        id: submitArrow
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 40
                        Text {
                            anchors.centerIn: parent
                            text: "→"
                            font.pixelSize: 25
                            color: root.accent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.submit()
                        }
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.errorMessage !== ""
                    text: root.errorMessage
                    wrapMode: Text.Wrap
                    color: "#ff7777"
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
        radius: 0
        color: "transparent"
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillColor: "black"
                PathSvg { path: root.notchPath(root.notchWidth, root.notchHeight) }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "󰌾"
            font.family: "IosevkaTerm Nerd Font"
            font.pixelSize: 18
            color: root.foreground
        }
    }

    // Quiet, notch-inspired footer; no platform-native gray controls.
    InputPanel {
        id: virtualKeyboard
        width: Math.min(root.width / 2, 600)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: footer.top
        anchors.bottomMargin: 12
        active: Qt.inputMethod.visible
        visible: root.keyboardRequested && root.loginVisible
        layer.enabled: true
        layer.effect: ShaderEffect {
            property color darkColor: Qt.darker(root.accent, 4)
            property color lightColor: root.foreground
            property size panelSize: Qt.size(virtualKeyboard.width, virtualKeyboard.height)
            property real cornerRadius: 16
            fragmentShader: "shaders/keyboard.frag.qsb"
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
        opacity: root.loginProgress * (root.exiting ? 0 : 1)
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 240 } }

        ComboBox {
            id: sessions
            width: 190
            height: 34
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
            font.pixelSize: 12
            background: Rectangle {
                radius: 17
                color: sessions.hovered || sessions.popup.visible ? "#303946" : "#cc000000"
                Behavior on color { ColorAnimation { duration: 160 } }
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
                Canvas {
                    id: sessionChevron
                    anchors.centerIn: parent
                    width: 12
                    height: 9
                    rotation: sessions.popup.visible ? 180 : 0
                    scale: sessions.hovered || sessions.popup.visible ? 1.2 : 1
                    Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.InOutCubic } }
                    Behavior on scale { NumberAnimation { duration: 160 } }
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = "#ffffff";
                        ctx.lineWidth = 1.8;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(2, 3);
                        ctx.lineTo(6, 7);
                        ctx.lineTo(10, 3);
                        ctx.stroke();
                    }
                }
            }
            delegate: ItemDelegate {
                width: sessions.width
                text: model.name
                highlighted: sessions.highlightedIndex === index
                contentItem: Text {
                    text: model.name
                    color: "white"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: highlighted ? "#303946" : "#171b22"; radius: 8 }
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
                background: Rectangle { color: "#171b22"; radius: 12 }
            }
        }

        Button {
            width: 36
            height: 34
            text: "⌨"
            ToolTip.visible: hovered
            ToolTip.text: "Teclado virtual"
            onClicked: {
                root.keyboardRequested = !root.keyboardRequested;
                if (root.keyboardRequested) {
                    password.forceActiveFocus();
                    Qt.inputMethod.show();
                } else {
                    Qt.inputMethod.hide();
                    password.forceActiveFocus();
                }
            }
            background: Rectangle { color: parent.hovered || root.keyboardRequested ? "#303946" : "#cc000000"; radius: 17 }
            contentItem: Item {
                Image { anchors.centerIn: parent; width: 24; height: 24; source: "icons/keyboard.svg"; fillMode: Image.PreserveAspectFit }
            }
        }

        Button {
            width: 36
            height: 34
            text: "‹"
            ToolTip.visible: hovered
            ToolTip.text: "Volver"
            onClicked: {
                root.view = "clock";
                root.choosingUser = false;
                root.forceActiveFocus();
            }
            background: Rectangle { color: parent.hovered ? "#303946" : "#cc000000"; radius: 17 }
            contentItem: Item {
                Image { anchors.centerIn: parent; width: 24; height: 24; source: "icons/chevron-left.svg"; fillMode: Image.PreserveAspectFit }
            }
        }
        Button {
            width: 36
            height: 34
            ToolTip.visible: hovered
            ToolTip.text: "Apagar"
            onClicked: sddm.powerOff()
            background: Rectangle { color: parent.hovered ? "#303946" : "#cc000000"; radius: 17 }
            contentItem: Item {
                Image { anchors.centerIn: parent; width: 24; height: 24; source: "icons/power.svg"; fillMode: Image.PreserveAspectFit }
            }
        }
        Button {
            width: 36
            height: 34
            ToolTip.visible: hovered
            ToolTip.text: "Reiniciar"
            onClicked: sddm.reboot()
            background: Rectangle { color: parent.hovered ? "#303946" : "#cc000000"; radius: 17 }
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: "icons/rotate-ccw.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (root.exiting || root.authenticating) {
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)) {
            root.previewExit();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape && root.view === "login") {
            root.view = "clock";
            root.choosingUser = false;
            root.forceActiveFocus();
            event.accepted = true;
        } else if (root.view === "clock") {
            root.showLogin();
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.view === "clock"
        onClicked: root.showLogin()
    }
}

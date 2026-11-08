import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root
    width: 1280
    height: 720
    focus: true

    // Standalone theme. SDDM and Quickshell intentionally do not share auth.
    // Ctrl+Shift+Return previews the exit morph in greeter test mode.
    property string view: "clock"
    property bool exiting: false
    property real reveal: 1
    property date now: new Date()
    property string errorMessage: ""
    readonly property color accent: "#adc6ff"
    readonly property color foreground: "#ffffff"
    readonly property color panel: "#000000"
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
    onLoginVisibleChanged: loginProgress = loginVisible ? 1 : 0
    function notchPath(w, h) {
        const e = Math.min(earRadius, h, w / 2);
        const corner = Math.max(0, Math.min(cornerRadius, h - e, w / 2 - e));
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
        if (exiting || password.text.length === 0)
            return;
        errorMessage = "";
        sddm.login(hasUsers ? userName : username.text,
                   password.text, sessions.currentIndex);
    }

    function previewExit() {
        if (exiting)
            return;
        exiting = true;
        exitMorph.start();
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
            root.exiting = false;
            root.reveal = 1;
            root.errorMessage = "No se pudo iniciar sesión";
            password.text = "";
            root.showLogin();
        }
        function onLoginSucceeded() {
            // SDDM may terminate the greeter immediately. A true handoff
            // animation is deferred to the follow-up integration story.
            root.previewExit();
        }
    }

    NumberAnimation {
        id: exitMorph
        target: root
        property: "reveal"
        from: 1
        to: 0
        duration: 400
        easing.type: Easing.InOutCubic
    }

    Rectangle {
        anchors.fill: parent
        color: "#141a23"
    }

    Item {
        id: morph
        width: root.notchWidth + (root.width - root.notchWidth) * root.reveal
        height: root.notchHeight + (root.height - root.notchHeight) * root.reveal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        clip: true

        // This is the first visual approximation. The final shared curved
        // notch mask will be ported from the wallpaper picker in phase 3.
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
                visible: status === Image.Ready
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
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(root.now, "hh:mm")
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: 100
                        scale: 1 - 0.4 * root.loginProgress
                        transformOrigin: Item.Center
                        color: "white"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(root.now, Qt.locale("es_GT"), "dddd, d MMMM yyyy")
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: 23
                        scale: 1 - (5 / 23) * root.loginProgress
                        transformOrigin: Item.Center
                        color: "white"
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
                                ctx.fillStyle = "#f4f7ff";
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
                        color: "white"
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
                        color: "white"
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
                            color: "white"
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

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32
                visible: root.view === "clock"
                opacity: root.reveal
                text: "Presiona una tecla para continuar"
                font.family: "IosevkaTerm Nerd Font"
                font.pixelSize: 14
                color: root.foreground
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

    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12
        visible: root.view === "login" && !root.exiting

        ComboBox {
            id: sessions
            width: 180
            model: sessionModel
            textRole: "name"
        }
        Button {
            text: "Volver"
            onClicked: {
                root.view = "clock";
                root.choosingUser = false;
                root.forceActiveFocus();
            }
        }
        Button {
            text: "Apagar"
            onClicked: sddm.powerOff()
        }
        Button {
            text: "Reiniciar"
            onClicked: sddm.reboot()
        }
    }

    Keys.onPressed: event => {
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

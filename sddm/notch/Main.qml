import QtQuick
import QtQuick.Controls
import QtQuick.Effects

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
    readonly property real notchWidth: 420
    readonly property real notchHeight: 62
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
                height: root.loginVisible ? 120 : 190
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.loginVisible ? root.height * 0.22 : (root.height - height) / 2
                opacity: root.reveal
                Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
                Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(root.now, "hh:mm")
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: root.loginVisible ? 60 : 100
                        Behavior on font.pixelSize { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
                        color: "white"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(root.now, Qt.locale("es_GT"), "dddd, d MMMM yyyy")
                        font.family: "IosevkaTerm Nerd Font"
                        font.pixelSize: root.loginVisible ? 18 : 23
                        Behavior on font.pixelSize { NumberAnimation { duration: 360 } }
                        color: "white"
                    }
                }
            }

            Column {
                id: loginPanel
                width: 320
                spacing: 14
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.loginVisible ? root.height * 0.48 : root.height * 0.54
                opacity: root.loginVisible ? root.reveal : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 240 } }
                Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }

                Item {
                    width: parent.width
                    height: root.choosingUser && root.hasUsers ? 118 : 80
                    Behavior on height { NumberAnimation { duration: 220 } }

                    Rectangle {
                        id: avatarCircle
                        width: 64
                        height: 64
                        radius: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#171b22"
                        clip: true

                        Image {
                            id: face
                            anchors.fill: parent
                            source: root.avatarPath === "" ? "" : (root.avatarPath.indexOf(":/") >= 0 ? root.avatarPath : "file://" + root.avatarPath)
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !face.visible
                            text: "󰀄"
                            color: "white"
                            font.family: "IosevkaTerm Nerd Font"
                            font.pixelSize: 29
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
                        anchors.topMargin: 30
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
                    height: 48
                    radius: 24
                    color: "#000000"

                    TextField {
                        id: password
                        anchors.left: parent.left
                        anchors.right: submitArrow.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        leftPadding: 18
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
                        width: 48
                        height: 48
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
        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#000000";
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.bezierCurveTo(width - 16, 0, width - 16, height, width - 32, height);
                ctx.lineTo(32, height);
                ctx.bezierCurveTo(16, height, 16, 0, 0, 0);
                ctx.closePath();
                ctx.fill();
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

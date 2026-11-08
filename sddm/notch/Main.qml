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
    property int selectedUser: 0
    readonly property bool loginVisible: view === "login"

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
        sddm.login(hasUsers ? userModel.data(userModel.index(selectedUser, 0), 257) : username.text,
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
        width: 190 + (root.width - 190) * root.reveal
        height: 32 + (root.height - 32) * root.reveal
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

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: root.loginVisible ? parent.height * 0.22 : parent.height * 0.19
                Behavior on anchors.topMargin { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
                spacing: 5
                opacity: root.reveal

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.now, "hh:mm")
                    font.family: "IosevkaTerm Nerd Font"
                    font.pixelSize: root.loginVisible ? 56 : 68
                    Behavior on font.pixelSize { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
                    color: root.foreground
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(root.now, Qt.locale("es_GT"), "dddd, d MMMM yyyy")
                    font.family: "IosevkaTerm Nerd Font"
                    font.pixelSize: 19
                    color: root.foreground
                }
            }

            Column {
                id: loginPanel
                visible: opacity > 0
                opacity: root.loginVisible ? root.reveal : 0
                y: root.loginVisible ? (parent.height - height) / 2 + 70 : (parent.height - height) / 2 + 92
                Behavior on opacity { NumberAnimation { duration: 240 } }
                Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Rectangle {
                    width: 320
                    height: loginItems.implicitHeight + 40
                    radius: 22
                    color: root.panel

                    Column {
                        id: loginItems
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.hasUsers ? "Iniciar sesión" : "Usuario"
                            font.family: "IosevkaTerm Nerd Font"
                            font.pixelSize: 17
                            color: root.foreground
                        }
                        ComboBox {
                            id: users
                            width: 270
                            visible: root.hasUsers
                            model: userModel
                            textRole: "name"
                            Connections {
                                target: users
                                function onActivated(index) { root.selectedUser = index; }
                            }
                        }
                        TextField {
                            id: username
                            width: 270
                            visible: !root.hasUsers
                            placeholderText: "Usuario"
                            onAccepted: password.forceActiveFocus()
                        }
                        TextField {
                            id: password
                            width: 270
                            height: 42
                            echoMode: TextInput.Password
                            placeholderText: "Contraseña"
                            onAccepted: root.submit()
                            background: Rectangle { radius: 18; color: "#202630"; border.color: password.activeFocus ? root.accent : "#353d49"; border.width: 1 }
                            color: root.foreground
                            placeholderTextColor: "#aab5c5"
                        }
                        Button {
                            width: 270
                            text: "Entrar"
                            onClicked: root.submit()
                            background: Rectangle { radius: 18; color: "#202630"; border.color: root.accent; border.width: 1 }
                            contentItem: Text { text: "Entrar"; color: root.foreground; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        Text {
                            width: 270
                            horizontalAlignment: Text.AlignHCenter
                            visible: root.errorMessage !== ""
                            text: root.errorMessage
                            wrapMode: Text.Wrap
                            color: "#ff7777"
                            font.pixelSize: 12
                        }
                    }
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
        width: 190
        height: 32
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
            font.pixelSize: 16
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

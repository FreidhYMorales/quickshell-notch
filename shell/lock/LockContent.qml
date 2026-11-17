import QtQuick
import "../config"
import "../logic/format.mjs" as Format
import "../logic/lockStage.mjs" as LockStage
import "../services"

// Visual lock content. Authentication stays in the shared LockPam instance;
// this component never changes Session.locked or releases the session lock.
Item {
    id: root

    required property var auth
    // "normal" keeps today's lock. "screensaver" and "black" belong to a lock
    // that came from idleness: they show no clock, hint or form until an input
    // ends them, which the surface that owns the stage then does.
    property string stage: "normal"
    readonly property bool contentShown: LockStage.lockLooks(stage).content
    signal woke
    property var screen: null
    readonly property var scheme: Colours.paletteFor(root.screen)
    property bool showingLogin: false
    property real loginProgress: showingLogin ? 1 : 0

    Behavior on loginProgress {
        NumberAnimation {
            duration: 440
            easing.type: Easing.InOutCubic
        }
    }

    function showLogin() {
        showingLogin = true;
        Qt.callLater(() => field.forceActiveFocus());
    }

    function showClock() {
        showingLogin = false;
        field.text = "";
        root.forceActiveFocus();
    }

    // Called by the surface once it ends a screensaver or black stage.
    function wake() {
        showLogin();
    }

    onStageChanged: {
        pointer.base = null;
        if (root.stage !== "normal")
            root.forceActiveFocus();
    }

    function submitPassword() {
        if (field.text.length === 0)
            return;
        root.auth.submit(field.text);
        field.text = "";
    }

    focus: true
    Keys.onPressed: event => {
        if (!root.contentShown) {
            root.woke();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape && root.showingLogin) {
            root.showClock();
            event.accepted = true;
        } else if (!root.showingLogin && event.key !== Qt.Key_Control && event.key !== Qt.Key_Shift && event.key !== Qt.Key_Alt && event.key !== Qt.Key_Meta) {
            root.showLogin();
            event.accepted = true;
        }
    }

    // Hover-only catcher for the stages without content: a real pointer move
    // ends them, while the pointer merely landing on the surface does not.
    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        property var base: null

        onPositionChanged: mouse => {
            if (root.contentShown)
                return;
            if (pointer.base === null) {
                pointer.base = {
                    x: mouse.x,
                    y: mouse.y
                };
                return;
            }
            if (LockStage.movedPast(pointer.base, {
                x: mouse.x,
                y: mouse.y
            }, Layout.lockMoveThreshold))
                root.woke();
        }
    }

    Item {
        id: clockGroup

        objectName: "lock-clock"
        visible: root.contentShown
        width: Math.min(parent.width, 650)
        height: 170
        anchors.horizontalCenter: parent.horizontalCenter
        y: (root.height - height) / 2 + (root.height * 0.22 - (root.height - height) / 2) * root.loginProgress
        scale: 1 - 0.30 * root.loginProgress
        transformOrigin: Item.Center

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Format.clock(Time.hours, Time.minutes)
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: 100
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const minute = Time.minutes;
                    return Qt.formatDate(new Date(), Qt.locale("es_GT"), "dddd, d MMMM yyyy");
                }
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: 23
            }
        }
    }

    Column {
        id: loginPanel

        objectName: "lock-form"
        width: Math.min(284, root.width - 32)
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * (0.46 + 0.035 * (1 - root.loginProgress))
        spacing: 12
        opacity: root.loginProgress
        visible: opacity > 0

        Item {
            width: parent.width
            height: 146

            Rectangle {
                id: avatar
                width: 116
                height: 116
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: Colours.cardFor(root.screen)

                Canvas {
                    anchors.centerIn: parent
                    width: 72
                    height: 72
                    property color glyphColor: root.scheme.onSurface
                    onGlyphColorChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = glyphColor;
                        ctx.beginPath();
                        ctx.arc(36, 24, 13, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.beginPath();
                        ctx.moveTo(12, 65);
                        ctx.bezierCurveTo(12, 35, 60, 35, 60, 65);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            Text {
                anchors.top: avatar.bottom
                anchors.topMargin: 7
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.auth.user
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.body
            }
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: height / 2
            color: Colours.background

            TextInput {
                id: field
                anchors.left: parent.left
                anchors.right: submitButton.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.body
                onAccepted: root.submitPassword()
                Keys.onEscapePressed: root.showClock()
            }

            Text {
                id: submitButton
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "→"
                color: root.scheme.primary
                font.pixelSize: 25

                TapHandler {
                    onTapped: root.submitPassword()
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.auth.fingerprintEnabled
            text: Strings.glyphFingerprint
            color: root.auth.fingerprintState === "error" ? Colours.critical : root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.polkitFingerprint
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: root.auth.error !== ""
            text: root.auth.error
            color: Colours.critical
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }
    }

    Text {
        objectName: "lock-hint"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        visible: !root.showingLogin && root.contentShown
        text: "Presiona una tecla para continuar"
        color: root.scheme.onSurface
        font.family: Fonts.family
        font.pixelSize: Fonts.body
    }

    TapHandler {
        enabled: !root.showingLogin
        onTapped: {
            if (root.contentShown)
                root.showLogin();
            else
                root.woke();
        }
    }

    Connections {
        target: root.auth
        function onErrorChanged() {
            if (root.auth.error !== "") {
                field.text = "";
                root.showLogin();
            }
        }
    }
}

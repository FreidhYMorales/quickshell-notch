import QtQuick
import "../config"
import "../logic/format.mjs" as Format
import "../services"

// Minimal lock screen content: clock, masked password field, fingerprint
// state and the last error. The session lock surface draws the wallpaper
// behind it; `auth` is the one LockPam shared by every monitor.
Item {
    id: root

    required property var auth
    property var screen: null
    readonly property var scheme: Colours.paletteFor(root.screen)

    Column {
        anchors.centerIn: parent
        spacing: Layout.lockGap

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Format.clock(Time.hours, Time.minutes)
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.lockClock
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Layout.lockFieldWidth
            height: Layout.lockFieldHeight
            radius: height / 2
            color: Colours.cardFor(root.screen)

            TextInput {
                id: field

                anchors.fill: parent
                anchors.leftMargin: Layout.lockFieldPad
                anchors.rightMargin: Layout.lockFieldPad
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                focus: true
                echoMode: TextInput.Password
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.title
                onAccepted: root.auth.submit(text)
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
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.auth.error !== ""
            text: root.auth.error
            color: Colours.critical
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }
    }

    // A failed attempt empties the field for the next one.
    Connections {
        target: root.auth

        function onErrorChanged() {
            if (root.auth.error !== "")
                field.text = "";
        }
    }
}

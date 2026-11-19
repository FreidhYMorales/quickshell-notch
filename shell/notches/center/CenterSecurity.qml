pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/fingerprint.mjs" as Fingerprint

// Security sub-view of the launcher: fingerprint unlock for the lock screen.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)

    signal back

    Keys.onEscapePressed: back()

    implicitHeight: content.implicitHeight

    Column {
        id: content

        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            width: parent.width
            text: Strings.securityTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        Text {
            objectName: "security-switch"
            text: (Security.fingerprintEnabled ? Strings.idleSwitchOn : Strings.idleSwitchOff) + "  " + Strings.securityFingerprintUnlock
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Security.setFingerprintEnabled(!Security.fingerprintEnabled)
            }
        }

        Column {
            objectName: "security-registered"
            width: parent.width
            spacing: Layout.launcherGap

            Text {
                text: Strings.securityRegistered
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            Repeater {
                model: Security.enrolled

                Text {
                    required property string modelData

                    text: Strings.fingerLabels[modelData] ?? modelData
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.launcherItem
                }
            }
        }

        Column {
            objectName: "security-free"
            width: parent.width
            spacing: Layout.launcherGap

            Text {
                text: Strings.securityAdd
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            Flow {
                width: parent.width
                spacing: Layout.launcherGap

                Repeater {
                    model: Fingerprint.freeFingers(Security.enrolled)

                    Text {
                        required property string modelData

                        objectName: "security-add-" + modelData
                        text: Strings.fingerLabels[modelData] ?? modelData
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Security.startEnroll(parent.modelData)
                        }
                    }
                }
            }
        }

        Column {
            visible: Security.enrolling
            width: parent.width
            spacing: Layout.launcherGap

            Text {
                objectName: "security-enroll-title"
                text: Strings.securityEnrolling.arg(Strings.fingerLabels[Security.enrollingFinger] ?? Security.enrollingFinger)
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            Text {
                objectName: "security-enroll-hint"
                text: Strings.enrollHints[Security.enrollHint] ?? Strings.enrollRetry
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            Text {
                objectName: "security-enroll-touches"
                text: Strings.securityTouches.arg(Security.enrollTouches)
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }
        }
    }
}

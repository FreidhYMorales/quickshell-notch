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
    onVisibleChanged: Security.setVerificationMonitoring(visible)
    Component.onDestruction: Security.setVerificationMonitoring(false)

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

        Item {
            objectName: "security-hands"
            width: parent.width
            height: Layout.securityHandsHeight

            Repeater {
                model: Fingerprint.fingerLayout()

                delegate: Item {
                    id: finger

                    required property var modelData

                    readonly property bool registered: Security.enrolled.indexOf(modelData.name) !== -1
                    readonly property bool matched: Security.matchedFinger === modelData.name
                    readonly property bool hovered: hover.hovered
                    property int seenMatch: Security.matchSequence

                    objectName: "security-print-" + modelData.name
                    x: modelData.x * (parent.width - width)
                    y: Layout.securityFingerTopMargin + modelData.y
                    width: Layout.securityFingerSize
                    height: Layout.securityFingerSize
                    rotation: modelData.rotation
                    scale: hovered ? Layout.securityFingerHoverScale : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: Timings.securityFingerHover
                            easing.type: Easing.OutCubic
                        }
                    }

                    onSeenMatchChanged: {
                        if (Security.matchedFinger === modelData.name)
                            pulse.restart();
                    }

                    Text {
                        id: printGlyph

                        anchors.fill: parent
                        text: Strings.glyphFingerprint
                        color: finger.hovered ? (finger.registered ? Colours.securityRemoveHover : Colours.securityAddHover) : finger.matched ? root.scheme.onSurface : finger.registered ? root.scheme.primary : root.scheme.muted
                        font.family: Fonts.family
                        font.pixelSize: Layout.securityFingerGlyph
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: Timings.securityMatchFlash / 3
                            }
                        }
                    }

                    HoverHandler {
                        id: hover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (finger.registered)
                                Security.removeFinger(finger.modelData.name);
                            else
                                Security.startEnroll(finger.modelData.name);
                        }
                    }

                    SequentialAnimation {
                        id: pulse

                        NumberAnimation {
                            target: finger
                            property: "scale"
                            to: Layout.securityFingerPulseScale
                            duration: Timings.securityFingerPulse
                            easing.type: Easing.OutBack
                        }

                        NumberAnimation {
                            target: finger
                            property: "scale"
                            to: 1
                            duration: Timings.securityFingerSettle
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: Strings.securityHandHint
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.small
            wrapMode: Text.WordWrap
        }

        Text {
            objectName: "security-switch"
            width: parent.width
            text: (Security.fingerprintEnabled ? Strings.idleSwitchOn : Strings.idleSwitchOff) + "  " + Strings.securityFingerprintUnlock
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
            wrapMode: Text.WordWrap

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Security.setFingerprintEnabled(!Security.fingerprintEnabled)
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

            Text {
                objectName: "security-enroll-cancel"
                text: Strings.securityCancel
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Security.cancelEnroll()
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../components"
import "../../config"
import "../../services"
import "../../logic/notifToast.mjs" as NotifToast

// Notification toast in the centre notch: one compact row (icon, "App:
// summary", +N queued); while hovered, a card of three lines: app and ✕,
// summary and body, the notification's own action buttons. A body click runs
// the default action. Every click closes the toast (Notifs.activate /
// Notifs.dismiss).
Item {
    id: root

    property var screen: null
    property bool expanded: false

    readonly property var notif: Notifs.current
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property var actions: NotifToast.toastActions(notif?.actions ?? [])
    readonly property string iconSource: notif ? NotifToast.toastIcon({
        image: notif.image,
        appIcon: notif.appIcon
    }, name => Quickshell.iconPath(name, true)) : ""

    component ToastText: Text {
        color: root.scheme.onSurface
        elide: Text.ElideRight
        maximumLineCount: 1
        textFormat: Text.PlainText
        font.family: Fonts.family
        font.pixelSize: Fonts.toast
    }

    NotchEarShape {
        anchors.fill: parent
    }

    // The body click sits under the header and buttons, which take their own clicks.
    MouseArea {
        anchors.fill: parent
        onClicked: Notifs.activate(root.actions.bodyAction)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Layout.earRadius + Layout.toastPad
        anchors.rightMargin: Layout.earRadius + Layout.toastPad
        anchors.bottomMargin: Layout.toastPadBottom

        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Layout.idleHeight

            // Fixed box: every icon, theme or picture, fits it the same way.
            Item {
                id: iconBox

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.toastIcon
                height: Layout.toastIcon

                Image {
                    id: icon

                    anchors.fill: parent
                    sourceSize: Qt.size(Layout.toastIcon * 2, Layout.toastIcon * 2)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    source: root.iconSource
                    visible: root.iconSource !== "" && status !== Image.Error
                }

                Text {
                    anchors.centerIn: parent
                    visible: !icon.visible
                    text: Strings.glyphBell
                    color: root.scheme.primary
                    font.family: Fonts.family
                    font.pixelSize: Fonts.toast
                }
            }

            ToastText {
                anchors.left: iconBox.right
                anchors.leftMargin: Layout.toastGap
                anchors.right: trailing.left
                anchors.rightMargin: Layout.toastGap
                anchors.verticalCenter: parent.verticalCenter
                text: root.notif ? (root.expanded ? root.notif.appName : root.notif.appName + Strings.toastAppSeparator + root.notif.summary) : ""
                color: root.expanded ? root.scheme.muted : root.scheme.onSurface
            }

            Row {
                id: trailing

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Layout.toastGap

                ToastText {
                    visible: Notifs.waiting > 0
                    text: Strings.toastWaitingPrefix + Notifs.waiting
                    color: root.scheme.muted
                }

                ToastText {
                    visible: root.expanded
                    text: Strings.glyphClose
                    color: root.scheme.muted

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Layout.toastGap / 2
                        onClicked: Notifs.dismiss(root.notif.id)
                    }
                }
            }
        }

        // Summary and body share one line, as in the plan's mockup.
        Row {
            id: message

            anchors.left: header.left
            anchors.leftMargin: Layout.toastIcon + Layout.toastGap
            anchors.right: header.right
            anchors.top: header.bottom
            spacing: Layout.toastGap
            visible: root.expanded

            ToastText {
                id: summary

                width: Math.min(implicitWidth, message.width / 2)
                text: root.notif?.summary ?? ""
                font.bold: true
            }

            ToastText {
                width: message.width - summary.width - message.spacing
                text: root.notif?.body ?? ""
                color: root.scheme.muted
            }
        }

        Row {
            anchors.left: message.left
            anchors.bottom: parent.bottom
            spacing: Layout.toastGap
            visible: root.expanded && root.actions.buttons.length > 0

            Repeater {
                model: root.actions.buttons

                Rectangle {
                    id: button

                    required property var modelData

                    width: label.implicitWidth + 2 * Layout.toastButtonPad
                    height: Layout.toastButtonHeight
                    radius: height / 2
                    color: Colours.cardFor(root.screen)

                    ToastText {
                        id: label

                        anchors.centerIn: parent
                        text: button.modelData.text
                        color: root.scheme.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifs.activate(button.modelData)
                    }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../components"
import "../../config"
import "../../services"
import "../../logic/notifToast.mjs" as NotifToast

// Notification toast in the centre notch: one compact row (icon, "App:
// summary", +N queued); while hovered, a card with the body, the
// notification's own action buttons and ✕. A body click runs the default
// action. Every click closes the toast (Notifs.activate / Notifs.dismiss).
Item {
    id: root

    property var screen: null
    property bool expanded: false

    readonly property var notif: Notifs.current
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property var actions: NotifToast.toastActions(notif?.actions ?? [])
    readonly property string iconSource: {
        if (!notif)
            return "";
        if (notif.image !== "")
            return notif.image;
        return notif.appIcon !== "" ? Quickshell.iconPath(notif.appIcon, true) : "";
    }

    component ToastText: Text {
        color: root.scheme.onSurface
        elide: Text.ElideRight
        font.family: Fonts.family
        font.pixelSize: Fonts.body
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
        anchors.leftMargin: Layout.earRadius + Layout.expandedPad
        anchors.rightMargin: Layout.earRadius + Layout.expandedPad

        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Layout.idleHeight

            Image {
                id: icon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.toastIcon
                height: Layout.toastIcon
                sourceSize: Qt.size(Layout.toastIcon, Layout.toastIcon)
                source: root.iconSource
                visible: root.iconSource !== ""
            }

            Text {
                anchors.centerIn: icon
                visible: !icon.visible
                text: Strings.glyphBell
                color: root.scheme.primary
                font.family: Fonts.family
                font.pixelSize: Fonts.body
            }

            ToastText {
                anchors.left: icon.right
                anchors.leftMargin: Layout.rowGap
                anchors.right: trailing.left
                anchors.rightMargin: Layout.rowGap
                anchors.verticalCenter: parent.verticalCenter
                text: root.notif ? (root.expanded ? root.notif.appName : root.notif.appName + Strings.toastAppSeparator + root.notif.summary) : ""
            }

            Row {
                id: trailing

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Layout.rowGap

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
                        anchors.margins: -Layout.rowGap / 2
                        onClicked: Notifs.dismiss(root.notif.id)
                    }
                }
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.leftMargin: Layout.toastIcon + Layout.rowGap
            spacing: Layout.toastLineGap
            visible: root.expanded

            ToastText {
                width: parent.width
                text: root.notif?.summary ?? ""
                font.bold: true
            }

            ToastText {
                width: parent.width
                text: root.notif?.body ?? ""
                visible: text !== ""
                color: root.scheme.muted
                textFormat: Text.PlainText
            }

            Row {
                spacing: Layout.rowGap
                visible: root.actions.buttons.length > 0

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
}

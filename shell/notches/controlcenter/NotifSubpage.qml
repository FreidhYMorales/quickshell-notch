pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Notifications subpage: Back and Clear on the header, the DND toggle, then
// every notification of the session newest first in a scrolling list, each one
// dismissable on its own. Fills the panel in place of the root content.
Rectangle {
    id: root

    property var scheme

    signal backRequested

    readonly property int count: Notifs.history.length
    readonly property color tint: {
        const p = Qt.color(scheme.primary);
        return Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
    }

    width: Layout.ccListWidth
    height: column.implicitHeight + 2 * Layout.ccCardPad
    radius: Layout.cardRadius
    color: tint

    Column {
        id: column

        x: Layout.ccCardPad
        y: Layout.ccCardPad
        width: root.width - 2 * Layout.ccCardPad
        spacing: Layout.ccRowGap

        Item {
            width: parent.width
            height: Layout.ccClearButton

            // Round buttons like the clear ✕ of the root: the tinted
            // circle only shows under the pointer.
            Item {
                id: backButton

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.ccClearButton
                height: width

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: backHover.hovered ? root.scheme.primary : root.tint

                    Behavior on color {
                        ColorAnimation {
                            duration: Timings.animFast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Strings.glyphChevronLeft
                        color: backHover.hovered ? Colours.background : root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }
                }

                HoverHandler {
                    id: backHover

                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.backRequested()
                }
            }

            Text {
                anchors.left: backButton.right
                anchors.leftMargin: Layout.ccRowPad
                anchors.right: dndPill.left
                anchors.rightMargin: Layout.ccRowPad
                anchors.verticalCenter: parent.verticalCenter
                text: Strings.notificationsTitle.arg(root.count)
                color: root.scheme.onSurface
                elide: Text.ElideRight
                font.family: Fonts.family
                font.pixelSize: Fonts.toast
            }

            // DND as a pill: the knob slides and the track fills when it is
            // on, and the bell turns into the muted bell.
            Item {
                id: dndPill

                anchors.right: clearButton.left
                anchors.rightMargin: Layout.ccRowPad
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.ccPill
                height: Layout.ccClearButton

                readonly property color accent: Qt.color(root.scheme.primary)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Notifs.dnd ? dndPill.accent : Qt.rgba(dndPill.accent.r, dndPill.accent.g, dndPill.accent.b, Colours.tileOffAlpha)

                    Behavior on color {
                        ColorAnimation {
                            duration: Timings.animFast
                        }
                    }
                }

                Rectangle {
                    id: knob

                    x: Notifs.dnd ? parent.width - width - 2 : 2
                    y: (parent.height - height) / 2
                    width: Layout.ccKnob
                    height: width
                    radius: width / 2
                    color: Colours.background

                    Behavior on x {
                        Anim {}
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Notifs.dnd ? Strings.glyphDnd : Strings.glyphBell
                        color: Notifs.dnd ? dndPill.accent : root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.small
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifs.toggleDnd()
                }
            }

            Item {
                id: clearButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.ccClearButton
                height: width
                visible: root.count > 0

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: clearHover.hovered ? root.scheme.primary : root.tint

                    Behavior on color {
                        ColorAnimation {
                            duration: Timings.animFast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Strings.glyphClose
                        color: clearHover.hovered ? Colours.background : root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }
                }

                HoverHandler {
                    id: clearHover

                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifs.clearAll()
                }
            }
        }

        // A fixed viewport: the whole history scrolls inside it, so the panel
        // never grows past its window.
        Flickable {
            id: flick

            width: parent.width
            height: Layout.ccListHeight
            visible: root.count > 0
            contentHeight: rows.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: rows

                width: flick.width
                spacing: Layout.ccRowGap

                Repeater {
                    model: Notifs.history

                    Rectangle {
                        id: row

                        required property var modelData

                        width: rows.width
                        height: Layout.ccRow
                        radius: Layout.ccRowRadius
                        color: root.tint

                        NotifIcon {
                            id: icon

                            anchors.left: parent.left
                            anchors.leftMargin: Layout.ccRowPad
                            anchors.verticalCenter: parent.verticalCenter
                            notif: row.modelData
                            scheme: root.scheme
                            size: Layout.ccRowIcon
                            glyphSize: Fonts.toast
                        }

                        Text {
                            anchors.left: icon.right
                            anchors.leftMargin: Layout.ccRowPad
                            anchors.right: dismiss.left
                            anchors.rightMargin: Layout.ccRowPad
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.appName + Strings.toastAppSeparator + row.modelData.summary
                            color: root.scheme.onSurface
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                            font.family: Fonts.family
                            font.pixelSize: Fonts.toast
                        }

                        // ✕ closes only this one: its app is told, the count drops.
                        Item {
                            id: dismiss

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Layout.ccClearButton
                            height: parent.height

                            Text {
                                anchors.centerIn: parent
                                text: Strings.glyphClose
                                color: dismissHover.hovered ? root.scheme.primary : root.scheme.muted
                                font.family: Fonts.family
                                font.pixelSize: Fonts.small
                            }

                            HoverHandler {
                                id: dismissHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: row.modelData.dismiss()
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.count === 0
            text: Strings.noNotifications
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.toast
        }
    }
}

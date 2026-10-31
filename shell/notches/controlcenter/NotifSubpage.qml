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

            Row {
                id: backButton

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Layout.ccRowPad

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Strings.glyphChevronLeft
                    color: backHover.hovered ? root.scheme.primary : root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.body
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Strings.back
                    color: backHover.hovered ? root.scheme.primary : root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.toast
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
                anchors.centerIn: parent
                text: Strings.notificationsTitle.arg(root.count)
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.toast
            }

            Item {
                id: clearButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: clearLabel.width
                height: parent.height
                visible: root.count > 0

                Text {
                    id: clearLabel

                    anchors.centerIn: parent
                    text: Strings.clearAll
                    color: clearHover.hovered ? root.scheme.primary : root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.toast
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

        // Do-not-disturb keeps its own toggle here, next to the list it mutes.
        Item {
            width: parent.width
            height: Layout.ccTile

            ControlTile {
                id: dndTile

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                scheme: root.scheme
                on: Notifs.dnd
                glyph: Strings.glyphDnd
                onToggled: Notifs.toggleDnd()
            }

            Text {
                anchors.left: dndTile.right
                anchors.leftMargin: Layout.ccRowPad
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Strings.dndLabel
                color: root.scheme.onSurface
                elide: Text.ElideRight
                font.family: Fonts.family
                font.pixelSize: Fonts.toast
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

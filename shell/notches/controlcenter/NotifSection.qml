pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../services"
import "../../logic/notifHistory.mjs" as NotifHistory

// Control center notifications on one translucent card: "Notifications (N)"
// with a round ✕ (clear all), a divider, then the newest few, each on its own
// card as "App: summary", or an empty line.
Rectangle {
    id: root

    property var scheme

    signal seeAllRequested

    readonly property int count: Notifs.history.length
    readonly property color tint: {
        const p = Qt.color(scheme.primary);
        return Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
    }

    width: Layout.ccListWidth
    height: list.implicitHeight + 2 * Layout.ccCardPad
    radius: Layout.cardRadius
    color: tint

    Column {
        id: list

        x: Layout.ccCardPad
        y: Layout.ccCardPad
        width: root.width - 2 * Layout.ccCardPad
        spacing: Layout.ccRowGap

        Item {
            width: parent.width
            height: Layout.ccClearButton

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Strings.notificationsTitle.arg(root.count)
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.toast
            }

            Rectangle {
                id: clearButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.count > 0
                width: Layout.ccClearButton
                height: Layout.ccClearButton
                radius: Layout.ccClearButton / 2
                color: clearHover.hovered ? root.scheme.primary : root.tint
                scale: clearHover.hovered || clearInput.activeFocus ? Layout.powerSelectedScale : 1

                Behavior on scale {
                    Anim {}
                }

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

                // The cursor lives on the HoverHandler: a MouseArea with
                // cursorShape takes the hover and the panel would collapse.
                HoverHandler {
                    id: clearHover

                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    id: clearInput

                    anchors.fill: parent
                    activeFocusOnTab: clearButton.visible
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            event.accepted = true;
                            if (!event.isAutoRepeat)
                                Notifs.clearAll();
                        }
                    }
                    onClicked: Notifs.clearAll()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: Layout.ccDivider
            color: root.scheme.muted
            opacity: Colours.dividerAlpha
        }

        Text {
            visible: root.count === 0
            text: Strings.noNotifications
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.toast
        }

        Repeater {
            model: NotifHistory.latest(Notifs.history, Limits.historyInline)

            Rectangle {
                id: row

                required property var modelData

                width: list.width
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
                    anchors.right: parent.right
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
            }
        }

        // "See all ›" opens the notifications subpage; hidden when empty.
        Item {
            width: parent.width
            height: Layout.ccClearButton
            visible: root.count > 0

            Text {
                id: seeAllText

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Strings.seeAll + " " + Strings.glyphChevronRight
                color: seeAllHover.hovered ? root.scheme.primary : root.scheme.muted
                scale: seeAllHover.hovered || seeAllInput.activeFocus ? Layout.powerSelectedScale : 1
                font.family: Fonts.family
                font.pixelSize: Fonts.small

                Behavior on scale {
                    Anim {}
                }
            }

            HoverHandler {
                id: seeAllHover

                cursorShape: Qt.PointingHandCursor
            }

            MouseArea {
                id: seeAllInput

                anchors.fill: parent
                activeFocusOnTab: parent.visible
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        event.accepted = true;
                        if (!event.isAutoRepeat)
                            root.seeAllRequested();
                    }
                }
                onClicked: root.seeAllRequested()
            }
        }
    }
}

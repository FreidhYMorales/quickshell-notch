pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../services"
import "../../logic/notifHistory.mjs" as NotifHistory

// Control center notifications: "Notifications (N)" with Clear, then the
// newest few as "App: summary" rows, or a single empty line.
Column {
    id: root

    property var scheme

    readonly property int count: Notifs.history.length

    width: Layout.ccListWidth
    spacing: Layout.ccRowGap

    Item {
        width: parent.width
        height: Layout.ccRow

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Strings.notificationsTitle.arg(root.count)
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.count > 0
            text: Strings.clearAll
            color: root.scheme.primary
            font.family: Fonts.family
            font.pixelSize: Fonts.body

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.clearAll()
            }
        }
    }

    Text {
        visible: root.count === 0
        text: Strings.noNotifications
        color: root.scheme.muted
        font.family: Fonts.family
        font.pixelSize: Fonts.body
    }

    Repeater {
        model: NotifHistory.latest(Notifs.history, Limits.historyInline)

        Item {
            id: row

            required property var modelData

            width: root.width
            height: Layout.ccRow

            NotifIcon {
                id: icon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                notif: row.modelData
                scheme: root.scheme
                size: Layout.ccRowIcon
                glyphSize: Fonts.body
            }

            Text {
                anchors.left: icon.right
                anchors.leftMargin: Layout.ccRowGap
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.appName + Strings.toastAppSeparator + row.modelData.summary
                color: root.scheme.onSurface
                elide: Text.ElideRight
                maximumLineCount: 1
                textFormat: Text.PlainText
                font.family: Fonts.family
                font.pixelSize: Fonts.body
            }
        }
    }
}

import QtQuick
import "../../components"
import "../../config"
import "../../logic/cornerLayout.mjs" as CornerLayout
import "../../logic/format.mjs" as Format
import "../../logic/workspaceStrip.mjs" as Strip
import "../../services"

// Control center (top-right). Collapsed it draws nothing and only a small
// corner hot zone takes input; resting there opens the panel, leaving the
// panel collapses it. The window is anchored right with its own fixed size.
NotchSurface {
    id: root

    readonly property var scheme: Colours.paletteFor(screen)
    property bool open: false
    readonly property var size: CornerLayout.cornerShape({
        contentWidth: header.implicitWidth,
        contentHeight: header.implicitHeight + 2 * Layout.ccPad,
        pad: Layout.ccPad,
        ear: Layout.earRadius,
        maxWidth: root.implicitWidth,
        maxHeight: root.implicitHeight
    })

    slotName: "tr"
    anchors.left: false
    anchors.right: true
    implicitWidth: Layout.ccWidth
    implicitHeight: Layout.ccHeight
    maskItem: maskBox

    CornerEarShape {
        id: shape

        x: root.width - width
        width: root.size.width
        height: root.size.height
        y: root.open ? 0 : -height
        anchor: "topRight"

        Behavior on y {
            Anim {}
        }

        Row {
            id: header

            x: Layout.earRadius + Layout.ccPad
            y: Layout.ccPad
            spacing: Layout.ccGap

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.ccAvatar
                height: Layout.ccAvatar
                radius: Layout.ccAvatar / 2
                color: Colours.cardFor(root.screen)

                Text {
                    anchors.centerIn: parent
                    text: Strip.appInitial(OsInfo.user, Strings.unknownInitial)
                    color: root.scheme.primary
                    font.family: Fonts.family
                    font.pixelSize: Fonts.title
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: OsInfo.user
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.title
                }

                Text {
                    // Missing uptime hides the line.
                    visible: OsInfo.uptime !== null
                    text: Strings.uptimePrefix + Format.formatUptime(OsInfo.uptime ?? 0)
                    color: root.scheme.muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.small
                }
            }
        }
    }

    // Input area: the hot zone while collapsed, the whole shape while open.
    Item {
        id: maskBox

        x: root.open ? shape.x : root.width - Layout.ccHotZone
        width: root.open ? shape.width : Layout.ccHotZone
        height: root.open ? shape.height : Layout.ccHotZone
    }

    NotchZone {
        anchors.fill: maskBox
        onHoverChanged: on => root.open = on
    }
}

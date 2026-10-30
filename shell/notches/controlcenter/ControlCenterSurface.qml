pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../logic/controlTiles.mjs" as ControlTiles
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
        contentWidth: panel.implicitWidth,
        contentHeight: panel.implicitHeight + 2 * Layout.ccPad,
        pad: Layout.ccPad,
        ear: Layout.earRadius,
        maxWidth: root.implicitWidth,
        maxHeight: root.implicitHeight
    })
    readonly property var tiles: ControlTiles.tilesFor({
        wifi: Radios.wifi,
        bt: Radios.bt,
        dnd: Notifs.dnd
    })
    // Per tile id: glyph, left click and right click.
    readonly property var tileInfo: ({
            wifi: {
                glyph: Strings.glyphWifi,
                toggle: Radios.toggleWifi,
                detail: Radios.openWifiTui
            },
            bt: {
                glyph: Strings.glyphBluetooth,
                toggle: Radios.toggleBt,
                detail: Radios.openBtTui
            },
            dnd: {
                glyph: Strings.glyphDnd,
                toggle: Notifs.toggleDnd,
                // The notifications subpage arrives with #05.
                detail: () => {}
            }
        })
    readonly property var body: CornerLayout.cornerBody(size, Layout.earRadius, "topRight")

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

        Column {
            id: panel

            x: Layout.earRadius + Layout.ccPad
            y: Layout.ccPad
            spacing: Layout.ccGap

            Row {
                id: header

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

            Row {
                spacing: Layout.ccTileGap

                Repeater {
                    model: root.tiles

                    ControlTile {
                        required property var modelData

                        scheme: root.scheme
                        on: modelData.on
                        glyph: root.tileInfo[modelData.id].glyph
                        onToggled: root.tileInfo[modelData.id].toggle()
                        onDetailRequested: root.tileInfo[modelData.id].detail()
                    }
                }
            }
        }
    }

    // Input area: the hot zone while collapsed, the drawn body (no ears)
    // while open, so leaving the visible edge collapses the panel.
    Item {
        id: maskBox

        x: root.open ? shape.x + root.body.x : root.width - Layout.ccHotZone
        width: root.open ? root.body.width : Layout.ccHotZone
        height: root.open ? root.body.height : Layout.ccHotZone
    }

    NotchZone {
        anchors.fill: maskBox
        onHoverChanged: on => root.open = on
    }
}

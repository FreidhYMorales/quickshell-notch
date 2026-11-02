pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../logic/controlNav.mjs" as ControlNav
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
    // 0 hidden .. 1 shown; animated instead of y (see slideOffset).
    property real progress: open ? 1 : 0
    // Root content, or the notifications subpage.
    property string view: ControlNav.initialView()
    readonly property bool rootView: view === ControlNav.ROOT
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
                detail: () => root.showNotifications()
            }
        })
    readonly property var body: CornerLayout.cornerBody(size, Layout.earRadius, "topRight")

    // Both entries ("See all" and the DND right click) open the subpage, and
    // only opening it clears the unread dot.
    function showNotifications() {
        view = ControlNav.openSubpage();
        Notifs.markSeen();
    }

    // Collapsing keeps the view, so the slide-out still shows what the user
    // was on; a fresh open resets it to the root.
    function collapse() {
        leaveTimer.stop();
        open = false;
    }

    slotName: "tr"
    Behavior on progress {
        Anim {}
    }
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
        y: CornerLayout.slideOffset(height, root.progress)
        anchor: "topRight"

        // Ancestor of every button: stays hovered while one of them takes
        // the hover from the zone below (input stops at the mask, so the
        // transparent ears never count).
        HoverHandler {
            id: panelHover

            // Any hover on the shape cancels a pending close, even before the
            // zone's own (debounced) hover is reported.
            onHoveredChanged: if (hovered)
                leaveTimer.stop()
        }

        Item {
            id: panel

            x: Layout.earRadius + Layout.ccPad
            y: Layout.ccPad
            // Both views are built even while hidden, so the panel always
            // knows the root's height (see panelHeight).
            implicitWidth: Math.max(rootView.implicitWidth, subView.width)
            implicitHeight: ControlNav.panelHeight(root.view, rootView.implicitHeight, subView.height)

            Column {
                id: rootView

                visible: root.rootView
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

                    ControlTile {
                        scheme: root.scheme
                        glyph: Strings.glyphRecording
                        onToggled: Recorder.start()
                    }
                }

                NotifSection {
                    scheme: root.scheme
                    onSeeAllRequested: root.showNotifications()
                }
            }

            NotifSubpage {
                id: subView

                visible: !root.rootView
                scheme: root.scheme
                minHeight: rootView.implicitHeight
                onBackRequested: root.view = ControlNav.back()
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

    // Below the content, so the buttons get their own hover; while one has
    // it, the panel's ancestor hover keeps the zone hovered.
    // A brief pointer leave must not close a subpage; the longer leave does.
    NotchZone {
        z: -1
        anchors.fill: maskBox
        alsoHovered: panelHover.hovered
        onHoverChanged: on => {
            if (on) {
                leaveTimer.stop();
                if (!root.open)
                    root.view = ControlNav.initialView();
                root.open = true;
            } else if (ControlNav.closeOnLeave(root.view) === "now") {
                root.collapse();
            } else {
                leaveTimer.restart();
            }
        }
    }

    Timer {
        id: leaveTimer

        interval: Timings.ccLeave
        onTriggered: root.collapse()
    }
}

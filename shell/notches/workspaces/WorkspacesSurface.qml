import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../components"
import "../../config"
import "../../logic/cornerLayout.mjs" as CornerLayout
import "../../logic/reveal.mjs" as Reveal
import "../../logic/workspaceStrip.mjs" as Strip
import "../../services"

// Workspaces notch (slot tl): Arch icon plus one slot per workspace, hidden
// until Workspaces announces activity. The shape slides in from above; only
// the visible area takes input, and hovering keeps it open. A special
// workspace pins it (Arch plus the special's glyph).
NotchSurface {
    id: root

    readonly property string monitorName: screen.name
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property string special: Workspaces.specialByMonitor[monitorName] ?? ""
    property var reveal: Reveal.initialReveal()
    readonly property bool open: Reveal.isVisible(reveal)
    readonly property var strip: Strip.stripFor({
        activeId: Workspaces.snapshot.monitors[monitorName]?.activeId ?? 1,
        windows: Workspaces.normalWindows,
        monitor: monitorName,
        minSlots: Limits.workspaceSlots,
        special: special,
        flash: reveal.flash
    })
    readonly property var size: CornerLayout.cornerShape({
        contentWidth: row.implicitWidth,
        contentHeight: Layout.idleHeight,
        pad: Layout.wsPad,
        ear: Layout.earRadius,
        maxWidth: root.implicitWidth,
        maxHeight: slot.height
    })

    function step(event) {
        const r = Reveal.stepReveal(reveal, event);
        reveal = r.state;
        if (r.timer === "restart")
            hide.restart();
        else if (r.timer === "stop")
            hide.stop();
    }

    function activate(item) {
        if (item.kind === "special")
            Hypr.dispatch("workspace.toggle_special", [item.cls]);
        else
            Hypr.dispatch("focus", [
                {
                    workspace: item.id
                }
            ]);
    }

    slotName: "tl"
    minWidth: Layout.cornerMaxWidth
    // Hidden: expose only a small hot zone when tray apps exist.
    maskItem: maskBox
    onSpecialChanged: {
        if (special !== "" || reveal.pinned)
            step({
                type: "Pin",
                on: special !== ""
            });
    }

    Timer {
        id: hide

        interval: Timings.reveal
        onTriggered: root.step({
            type: "Timeout"
        })
    }

    Timer {
        interval: Timings.startupGate
        running: true
        onTriggered: root.step({
            type: "Ready"
        })
    }

    Connections {
        function onTriggered(monitor, events) {
            if (monitor !== root.monitorName)
                return;
            let flash;
            for (const e of events)
                if (e.kind === "open")
                    flash = {
                        workspaceId: e.workspaceId,
                        cls: e.cls
                    };
            root.step({
                type: "Trigger",
                flash: flash
            });
        }

        target: Workspaces
    }

    CornerEarShape {
        id: shape

        width: root.size.width
        height: root.size.height
        y: root.open ? 0 : -height
        anchor: "topLeft"

        Behavior on y {
            Anim {}
        }

        Row {
            id: row

            x: Layout.wsPad
            height: Layout.idleHeight
            spacing: Layout.wsGap

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Strings.glyphArch
                color: root.scheme.primary
                font.family: Fonts.family
                font.pixelSize: Layout.wsIcon
            }

            Repeater {
                model: root.reveal.row === "tray" && !root.strip.pinned ? [] : root.strip.pinned ? [
                    {
                        id: 0,
                        kind: "special",
                        cls: root.strip.special
                    }
                ] : root.strip.items

                WorkspaceSlot {
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    kind: modelData.kind
                    app: modelData.cls ?? ""
                    scheme: root.scheme
                    onClicked: root.activate(modelData)
                }
            }

            Repeater {
                model: root.reveal.row === "tray" && !root.strip.pinned ? SystemTray.items.values : []

                Item {
                    id: trayItem

                    required property var modelData
                    readonly property string iconSource: modelData.icon
                    readonly property string themePrefix: "image://icon/"
                    readonly property bool missingNamedIcon: iconSource.startsWith(themePrefix) && iconSource.indexOf("?") < 0 && Quickshell.iconPath(iconSource.slice(themePrefix.length), true) === ""

                    anchors.verticalCenter: parent.verticalCenter
                    width: Layout.wsIcon
                    height: Layout.wsIcon

                    Image {
                        anchors.fill: parent
                        visible: !trayItem.missingNamedIcon
                        source: trayItem.missingNamedIcon ? "" : trayItem.iconSource
                        sourceSize: Qt.size(Layout.wsIcon, Layout.wsIcon)
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: trayItem.missingNamedIcon
                        text: Strings.unknownInitial
                        color: root.scheme.primary
                        font.family: Fonts.family
                        font.pixelSize: Layout.wsIcon
                    }
                }
            }
        }
    }

    NotchZone {
        id: maskBox

        width: root.open ? shape.width : SystemTray.items.values.length > 0 ? Layout.wsHotZone : 0
        height: root.open ? shape.height : SystemTray.items.values.length > 0 ? Layout.wsHotZone : 0
        onHoverChanged: on => {
            if (on && !root.open)
                root.step({
                    type: "TrayHover",
                    count: SystemTray.items.values.length
                });
            else
                root.step({
                    type: "Hover",
                    on: on
                });
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../components"
import "../../config"
import "../../logic/cornerLayout.mjs" as CornerLayout
import "../../logic/reveal.mjs" as Reveal
import "../../logic/workspaceFlight.mjs" as Flight
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
    property var menuItem: null
    // Window move animation. `flyKind` is "fly" or "fade" (to a special);
    // fromX/toX are slot centres in the shape's coordinates.
    property bool flying: false
    property string flyKind: ""
    property real fromX: 0
    property real toX: 0
    // The destination slot stays empty until the move lands on it, then
    // appears through these two values.
    property int landingIndex: -1
    property real landingOpacity: 1
    property real landingScale: 1
    readonly property bool open: Reveal.isVisible(reveal)
    // Width of the option column: the widest label plus the check mark and the
    // side padding, capped to the notch body.
    readonly property real menuContentWidth: Math.min(Layout.cornerMaxWidth - 2 * Layout.wsPad - Layout.earRadius, menuMeasure.implicitWidth + Layout.wsMenuGlyph + Layout.wsGap + 2 * Layout.wsMenuPad)
    readonly property var strip: Strip.stripFor({
        activeId: Workspaces.snapshot.monitors[monitorName]?.activeId ?? 1,
        windows: Workspaces.normalWindows,
        monitor: monitorName,
        minSlots: Limits.workspaceSlots,
        special: special,
        flash: reveal.flash
    })
    readonly property var size: CornerLayout.cornerShape({
        contentWidth: Math.max(row.implicitWidth, menuItem ? menuContentWidth : 0),
        contentHeight: Layout.idleHeight + menuColumn.implicitHeight + (menuItem ? Layout.wsMenuSeparator + Layout.wsMenuPadBottom : 0),
        pad: Layout.wsPad,
        ear: Layout.earRadius,
        maxWidth: root.implicitWidth,
        maxHeight: root.implicitHeight
    })

    function step(event) {
        // Do not replace the tray while its exit animation is still visible.
        if (event.type === "Trigger" && !open && reveal.row === "tray" && shape.y > -shape.height)
            return;
        const r = Reveal.stepReveal(reveal, event);
        reveal = r.state;
        if (r.timer === "restart")
            hide.restart();
        else if (r.timer === "stop")
            hide.stop();
    }

    // Centre of slot `index` in the shape's coordinates.
    function slotCentre(index: int): real {
        const slot = slots.itemAt(index);
        return slot ? row.x + slot.x + slot.width / 2 : -1;
    }

    function stopFlights() {
        pillFlight.stop();
        dotFlight.stop();
        fadeFlight.stop();
    }

    function endFlight() {
        flying = false;
        landingIndex = -1;
        landingOpacity = 1;
        landingScale = 1;
    }

    // One flight at a time: a new move replaces the one in progress.
    function startFlight(f) {
        stopFlights();
        // A new strip rebuilds every slot; lay them out before reading x.
        row.forceLayout();
        fromX = slotCentre(f.from);
        if (fromX < 0)
            return;
        toX = f.kind === "fly" ? slotCentre(f.to) : fromX;
        flyKind = f.kind;
        flyer.app = f.cls;
        flyer.x = fromX - flyer.width / 2;
        flyer.opacity = 1;
        flyer.scale = 1;
        mover.opacity = 1;
        landingIndex = f.kind === "fly" ? f.to : -1;
        landingOpacity = 0;
        landingScale = Flags.flyStyle === "dot" ? 0 : 1;
        flying = true;
        if (f.kind === "fade") {
            fadeFlight.restart();
        } else if (Flags.flyStyle === "dot") {
            mover.width = Layout.dotSize;
            mover.x = fromX - Layout.dotSize / 2;
            mover.opacity = 0;
            dotFlight.restart();
        } else {
            mover.width = Layout.wsIcon;
            mover.x = fromX - Layout.wsIcon / 2;
            pillFlight.restart();
        }
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
    minHeight: menuItem ? Math.floor(screen.height / 2) : 0
    // Hidden: expose only a small hot zone when tray apps exist.
    maskItem: maskBox
    onOpenChanged: if (!open)
        menuItem = null
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
            for (const e of events)
                if (e.kind === "move") {
                    const f = Flight.flightFor({
                        move: e,
                        strip: root.strip,
                        row: root.reveal.row
                    });
                    if (f)
                        root.startFlight(f);
                }
        }

        target: Workspaces
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.menuItem ? root.menuItem.menu : null
    }

    CornerEarShape {
        id: shape

        width: root.size.width
        height: root.size.height
        y: root.open ? 0 : -height
        anchor: "topLeft"

        // Keeps the zone hovered while the pointer is anywhere on the shape,
        // including over menu options that take their own hover.
        HoverHandler {
            id: shapeHover
        }

        Behavior on y {
            Anim {}
        }

        // The moved app's icon at its source slot: it fades out there (to a
        // special, and under the pill) or shrinks into the dot.
        WorkspaceSlot {
            id: flyer

            objectName: root.flyKind === "fade" ? "ws-flyer" : ""
            z: 1
            y: row.y + (row.height - height) / 2
            visible: root.flying
            kind: "app"
            scheme: root.scheme
        }

        // What travels between the slots: an accent pill that stretches from
        // the source to the destination and contracts there, or a dot.
        Rectangle {
            id: mover

            objectName: root.flyKind === "fly" ? "ws-flyer" : ""
            z: 1
            height: Flags.flyStyle === "dot" ? Layout.dotSize : Layout.wsIcon
            radius: height / 2
            y: row.y + (row.height - height) / 2
            visible: root.flying && root.flyKind === "fly"
            color: root.scheme.primary
        }

        // Pill: stretch to cover both slots, then contract onto the destination,
        // which appears as the pill fades.
        SequentialAnimation {
            id: pillFlight

            ParallelAnimation {
                NumberAnimation {
                    target: mover
                    property: "x"
                    to: Math.min(root.fromX, root.toX) - Layout.wsIcon / 2
                    duration: Timings.animSlow / 2
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    target: mover
                    property: "width"
                    to: Math.abs(root.toX - root.fromX) + Layout.wsIcon
                    duration: Timings.animSlow / 2
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    target: flyer
                    property: "opacity"
                    to: 0
                    duration: Timings.animSlow / 2
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: mover
                    property: "x"
                    to: root.toX - Layout.wsIcon / 2
                    duration: Timings.animSlow / 2
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    target: mover
                    property: "width"
                    to: Layout.wsIcon
                    duration: Timings.animSlow / 2
                    easing.type: Easing.InOutCubic
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: mover
                    property: "opacity"
                    to: 0
                    duration: Timings.animFast
                }

                NumberAnimation {
                    target: root
                    property: "landingOpacity"
                    to: 1
                    duration: Timings.animFast
                }
            }

            ScriptAction {
                script: root.endFlight()
            }
        }

        // Dot: the icon shrinks into an accent dot, the dot travels, and the
        // destination icon grows out of it.
        SequentialAnimation {
            id: dotFlight

            ParallelAnimation {
                NumberAnimation {
                    target: flyer
                    property: "scale"
                    to: 0
                    duration: Timings.animSlow / 4
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: mover
                    property: "opacity"
                    to: 1
                    duration: Timings.animSlow / 4
                }
            }

            NumberAnimation {
                target: mover
                property: "x"
                to: root.toX - Layout.dotSize / 2
                duration: Timings.animSlow / 2
                easing.type: Easing.InOutCubic
            }

            ParallelAnimation {
                NumberAnimation {
                    target: mover
                    property: "opacity"
                    to: 0
                    duration: Timings.animSlow / 4
                }

                NumberAnimation {
                    target: root
                    property: "landingOpacity"
                    to: 1
                    duration: Timings.animSlow / 4
                }

                NumberAnimation {
                    target: root
                    property: "landingScale"
                    to: 1
                    duration: Timings.animSlow / 4
                    easing.type: Easing.OutBack
                }
            }

            ScriptAction {
                script: root.endFlight()
            }
        }

        // To a special: the icon just fades out at its slot.
        SequentialAnimation {
            id: fadeFlight

            NumberAnimation {
                target: flyer
                property: "opacity"
                to: 0
                duration: Timings.animSlow
            }

            ScriptAction {
                script: root.endFlight()
            }
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

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    enabled: SystemTray.items.values.length > 0 && !root.strip.pinned
                    onClicked: root.step({
                        type: "ToggleTray"
                    })
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.reveal.row === "tray" && !root.strip.pinned
                width: Layout.wsDivider
                height: Layout.wsIcon
                color: root.scheme.muted
                opacity: Colours.dividerAlpha
            }

            Repeater {
                id: slots

                model: root.reveal.row === "tray" && !root.strip.pinned ? [] : root.strip.pinned ? [
                    {
                        id: 0,
                        kind: "special",
                        cls: root.strip.special
                    }
                ] : root.strip.items

                WorkspaceSlot {
                    required property var modelData
                    required property int index

                    objectName: "ws-slot-" + modelData.id
                    opacity: index === root.landingIndex ? root.landingOpacity : 1
                    scale: index === root.landingIndex ? root.landingScale : 1
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
                    width: Layout.wsTrayIcon
                    height: Layout.wsTrayIcon

                    Image {
                        id: trayIcon

                        anchors.fill: parent
                        visible: !trayItem.missingNamedIcon && status !== Image.Error
                        source: trayItem.missingNamedIcon ? "" : trayItem.iconSource
                        sourceSize: Qt.size(Layout.wsTrayIcon, Layout.wsTrayIcon)
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: trayItem.missingNamedIcon || trayIcon.status === Image.Error
                        text: Strings.unknownInitial
                        color: root.scheme.primary
                        font.family: Fonts.family
                        font.pixelSize: Layout.wsIcon
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton)
                                trayItem.modelData.activate();
                            else if (trayItem.modelData.hasMenu)
                                root.menuItem = root.menuItem === trayItem.modelData ? null : trayItem.modelData;
                        }
                    }
                }
            }
        }

        // Hidden: measures the widest option label so the menu fits its
        // contents instead of taking the whole corner body.
        Column {
            id: menuMeasure

            visible: false
            Repeater {
                model: menuOpener.children
                Text {
                    required property var modelData
                    visible: !modelData.isSeparator
                    text: modelData.text
                    font.family: Fonts.family
                    font.pixelSize: Layout.wsIcon
                }
            }
        }

        Rectangle {
            x: Layout.wsPad + Layout.wsMenuPad
            y: Layout.idleHeight + (Layout.wsMenuSeparator - height) / 2
            width: root.menuContentWidth - 2 * Layout.wsMenuPad
            height: Layout.wsDivider
            visible: root.menuItem !== null
            color: root.scheme.muted
            opacity: Colours.dividerAlpha
        }

        Text {
            x: Layout.wsPad + (root.menuContentWidth - width) / 2
            y: menuViewport.y + menuViewport.height
            visible: root.menuItem !== null && menuViewport.contentY + menuViewport.height < menuViewport.contentHeight - 1
            text: Strings.glyphChevronDown
            color: root.scheme.primary
            font.family: Fonts.family
            font.pixelSize: Layout.wsMenuGlyph
        }

        Flickable {
            id: menuViewport

            x: Layout.wsPad
            y: Layout.idleHeight + Layout.wsMenuSeparator
            width: root.menuContentWidth
            height: Math.max(0, root.size.height - y - Layout.wsMenuPadBottom - Layout.earRadius)
            contentWidth: width
            contentHeight: menuColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: menuColumn
                Repeater {
                    model: menuOpener.children
                    Item {
                        required property var modelData
                        width: root.menuContentWidth
                        height: modelData.isSeparator ? Layout.wsMenuSeparator : Layout.wsMenuRow

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Layout.wsMenuPad
                            visible: modelData.isSeparator
                            width: root.menuContentWidth - 2 * Layout.wsMenuPad
                            height: Layout.wsDivider
                            color: root.scheme.muted
                            opacity: Colours.dividerAlpha
                        }

                        Row {
                            id: menuRow

                            x: Layout.wsMenuPad
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !modelData.isSeparator
                            spacing: Layout.wsGap

                            Text {
                                text: Strings.glyphCheck
                                visible: modelData.checkState === Qt.Checked
                                color: root.scheme.primary
                                font.family: Fonts.family
                                font.pixelSize: Layout.wsMenuGlyph
                            }

                            Text {
                                text: modelData.text
                                color: !modelData.enabled ? root.scheme.muted : rowHover.hovered ? root.scheme.primary : root.scheme.onSurface
                                font.family: Fonts.family
                                font.pixelSize: Layout.wsIcon
                            }
                        }

                        HoverHandler {
                            id: rowHover
                            enabled: modelData.enabled && !modelData.isSeparator
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: modelData.enabled && !modelData.isSeparator
                            onClicked: modelData.triggered()
                        }
                    }
                }
            }
        }
    }

    NotchZone {
        id: maskBox

        // Below the content so menu options get their own hover; the shape's
        // hover keeps the zone hovered meanwhile.
        z: -1
        alsoHovered: shapeHover.hovered
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

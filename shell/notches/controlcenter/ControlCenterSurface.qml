pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../logic/controlNav.mjs" as ControlNav
import "../../logic/controlTiles.mjs" as ControlTiles
import "../../logic/cornerLayout.mjs" as CornerLayout
import "../../logic/format.mjs" as Format
import "../../logic/powerMenu.mjs" as PowerMenu
import "../../logic/workspaceStrip.mjs" as Strip
import "../../services"
import "../center"

// Control center (top-right). Collapsed it draws nothing and only a small
// corner hot zone takes input; resting there opens the panel, leaving the
// panel collapses it. The window is anchored right with its own fixed size.
NotchSurface {
    id: root

    component ResourceDetailRow: Row {
        id: detail

        required property string label
        required property string value

        spacing: Layout.ccGap

        Text {
            text: detail.label
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }
        Text {
            text: detail.value
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }
    }

    readonly property var scheme: Colours.paletteFor(screen)
    // Defaults to the live service; tests can provide deterministic readings.
    property var resourceStats: SysInfo
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
        dnd: Notifs.dnd,
        profile: PowerProfile.current,
        caffeine: Caffeine.enabled
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
            },
            profile: {
                glyph: Strings.profileGlyphs[PowerProfile.current] ?? Strings.profileGlyphs.balanced,
                toggle: PowerProfile.cycle,
                detail: () => {}
            },
            caffeine: {
                glyph: Strings.glyphCaffeine,
                toggle: Caffeine.toggle,
                detail: () => {}
            }
        })
    readonly property var body: CornerLayout.cornerBody(size, Layout.earRadius, "topRight")

    // Re-read the profile when the panel opens: a change made elsewhere shows
    // up without a watcher process.
    onOpenChanged: if (open)
        PowerProfile.refresh()

    // Both entries ("See all" and the DND right click) open the subpage, and
    // only opening it clears the unread dot.
    function showNotifications() {
        view = ControlNav.openSubpage();
        Notifs.markSeen();
    }

    function showResources() {
        view = "resources";
    }

    function formatMemory(kib) {
        const mib = kib / 1024;
        return Number.isFinite(kib) ? (mib >= 1024 ? (mib / 1024).toFixed(1) + " GiB" : Math.round(mib) + " MiB") : Strings.resourcesMeasuring;
    }
    function formatMemoryPair(used, total) {
        return Number.isFinite(used) && Number.isFinite(total) ? formatMemory(used) + " / " + formatMemory(total) : Strings.resourcesMeasuring;
    }
    function formatBytes(bytes) {
        if (!Number.isFinite(bytes) || bytes < 0)
            return Strings.resourcesMeasuring;
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let value = bytes;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit += 1;
        }
        return (unit === 0 ? Math.round(value) : value.toFixed(1)) + " " + units[unit];
    }
    function formatBytePair(used, total) {
        return Number.isFinite(used) && Number.isFinite(total) ? formatBytes(used) + " / " + formatBytes(total) : Strings.resourcesMeasuring;
    }
    function detailStatus(status) {
        return status === "unavailable" ? Strings.resourcesUnavailable : Strings.resourcesMeasuring;
    }

    // A power row click always collapses the panel. Lock and suspend run here;
    // the session-ending ones open this monitor's power menu, preselected, so
    // they still need the hold.
    function powerClicked(action) {
        collapse();
        if (PowerMenu.needsHold(action))
            CenterStore.dispatch({
                type: "PowerOpen",
                monitor: screen.name,
                action: action
            });
        else
            Power.run(action);
    }

    // Collapsing keeps the view, so the slide-out still shows what the user
    // was on; a fresh open resets it to the root.
    function collapse() {
        leaveTimer.stop();
        open = false;
    }

    // Keybind entry: open on this monitor only, and only the notifications
    // subpage clears the unread dot.
    Connections {
        target: Requests

        function onControlCenter(view, monitor) {
            if (monitor !== root.screen.name)
                return;
            if (view === ControlNav.NOTIFICATIONS)
                root.showNotifications();
            else
                root.view = view;
            root.open = true;
        }
    }

    slotName: "tr"
    Behavior on progress {
        Anim {}
    }
    anchors.left: false
    anchors.right: true
    implicitWidth: Layout.ccWidth
    implicitHeight: Layout.ccHeight
    wantsKeyboard: root.view === "resources"
    maskItem: maskBox

    CornerEarShape {
        id: shape
        accentColor: root.scheme.primary

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
            implicitWidth: Math.max(rootView.implicitWidth, subView.width, resourceView.implicitWidth)
            implicitHeight: ControlNav.panelHeight(root.view, rootView.implicitHeight, Math.max(subView.height, resourceView.implicitHeight))

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
                    width: Layout.ccListWidth
                    spacing: Layout.ccTileGap

                    Repeater {
                        model: [
                            {
                                label: Strings.resourcesCpu,
                                value: root.resourceStats.cpu,
                                icon: Strings.glyphCpu
                            },
                            {
                                label: Strings.resourcesRam,
                                value: root.resourceStats.ram,
                                icon: Strings.glyphRam
                            },
                            {
                                label: Strings.resourcesDisk,
                                value: root.resourceStats.rootFilesystem ? root.resourceStats.rootFilesystem.usedPercent : null,
                                status: root.resourceStats.rootFilesystemStatus,
                                icon: Strings.glyphDisk
                            }
                        ]

                        Row {
                            id: resourceMetric

                            required property var modelData

                            width: (Layout.ccListWidth - 2 * Layout.ccTileGap) / 3
                            spacing: Layout.ccTileGap

                            ArcMeter {
                                anchors.verticalCenter: parent.verticalCenter
                                value: Number.isFinite(resourceMetric.modelData.value) ? resourceMetric.modelData.value : 0
                                icon: resourceMetric.modelData.icon
                                ringColor: root.scheme.primary
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: resourceMetric.modelData.label
                                    color: root.scheme.muted
                                    font.family: Fonts.family
                                    font.pixelSize: Fonts.small
                                }

                                Text {
                                    text: Number.isFinite(resourceMetric.modelData.value) ? Math.round(resourceMetric.modelData.value) + "%" : root.detailStatus(resourceMetric.modelData.status)
                                    color: root.scheme.onSurface
                                    font.family: Fonts.family
                                    font.pixelSize: Fonts.body
                                }
                            }
                        }
                    }
                }

                // Session actions, same icons and hover look as the power menu,
                // on a pill tinted like the notifications card. Tile-wide cells
                // spread edge to edge, so the icons line up with the tiles.
                Rectangle {
                    width: Layout.ccListWidth
                    height: Layout.ccTile
                    radius: height / 2
                    color: {
                        const p = Qt.color(root.scheme.primary);
                        return Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: (Layout.ccListWidth - PowerMenu.ACTIONS.length * Layout.ccTile) / (PowerMenu.ACTIONS.length - 1)

                        Repeater {
                            model: PowerMenu.ACTIONS

                            Text {
                                id: powerIcon

                                required property string modelData

                                width: Layout.ccTile
                                height: Layout.ccTile
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: Strings.powerIcons[modelData]
                                color: powerHover.hovered ? root.scheme.primary : root.scheme.onSurface
                                scale: powerHover.hovered ? Layout.powerSelectedScale : 1
                                font.family: Fonts.family
                                font.pixelSize: Fonts.control

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Timings.animNormal
                                    }
                                }

                                Behavior on scale {
                                    Anim {}
                                }

                                // Centre the drawn icon, not its narrower advance.
                                transform: Translate {
                                    x: PowerMenu.inkCentreOffset({
                                        advance: ink.advanceWidth,
                                        inkX: ink.tightBoundingRect.x,
                                        inkWidth: ink.tightBoundingRect.width
                                    })
                                }

                                TextMetrics {
                                    id: ink

                                    font: powerIcon.font
                                    text: powerIcon.text
                                }

                                HoverHandler {
                                    id: powerHover
                                }

                                TapHandler {
                                    onTapped: root.powerClicked(parent.modelData)
                                }
                            }
                        }
                    }
                }

                BatteryCard {
                    scheme: root.scheme
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
                        glyph: Recorder.recording || Recorder.preparingCapture ? Strings.glyphStop : Strings.glyphRecording
                        onToggled: {
                            if (Recorder.recording || Recorder.preparingCapture)
                                Recorder.stop();
                            else if (Recorder.countdown > 0)
                                Recorder.cancelCountdown();
                            else
                                Recorder.beginCountdown();
                        }
                    }
                }

                NotifSection {
                    scheme: root.scheme
                    onSeeAllRequested: root.showNotifications()
                }

                Text {
                    objectName: "cc-resource-entry"
                    text: Strings.resourcesTitle
                    color: root.scheme.primary
                    font.family: Fonts.family
                    font.pixelSize: Fonts.small

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.showResources()
                    }
                }
            }

            NotifSubpage {
                id: subView

                visible: root.view === ControlNav.NOTIFICATIONS
                scheme: root.scheme
                minHeight: rootView.implicitHeight
                onBackRequested: root.view = ControlNav.back()
            }

            Column {
                id: resourceView

                visible: root.view === "resources"
                focus: visible
                Keys.onEscapePressed: root.view = ControlNav.back()
                spacing: Layout.ccGap

                Row {
                    spacing: Layout.ccGap

                    Item {
                        objectName: "cc-resource-back"
                        width: Layout.ccClearButton
                        height: width

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: backHover.hovered ? root.scheme.primary : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Strings.glyphChevronLeft
                            color: backHover.hovered ? Colours.background : root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.body
                        }

                        HoverHandler {
                            id: backHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.view = ControlNav.back()
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.resourcesTitle
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.title
                    }
                }

                Row {
                    spacing: Layout.ccGap

                    Text {
                        text: Strings.resourcesCpu
                        color: root.scheme.muted
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }

                    Text {
                        text: Number.isFinite(root.resourceStats.cpu) ? Math.round(root.resourceStats.cpu) + "%" : Strings.resourcesMeasuring
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }
                }

                Row {
                    spacing: Layout.ccGap

                    Text {
                        text: Strings.resourcesRam
                        color: root.scheme.muted
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }

                    Text {
                        text: Number.isFinite(root.resourceStats.ram) ? Math.round(root.resourceStats.ram) + "%" : Strings.resourcesMeasuring
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }
                }

                ResourceDetailRow {
                    label: Strings.resourcesMemoryLabels[0]
                    value: root.resourceStats.memoryDetails ? root.formatMemoryPair(root.resourceStats.memoryDetails.usedKiB, root.resourceStats.memoryDetails.totalKiB) : root.detailStatus(root.resourceStats.memoryDetailsStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesMemoryLabels[1]
                    value: root.resourceStats.memoryDetails ? root.formatMemory(root.resourceStats.memoryDetails.availableKiB) : root.detailStatus(root.resourceStats.memoryDetailsStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesMemoryLabels[2]
                    value: root.resourceStats.memoryDetails ? root.formatMemoryPair(root.resourceStats.memoryDetails.swapUsedKiB, root.resourceStats.memoryDetails.swapTotalKiB) : root.detailStatus(root.resourceStats.memoryDetailsStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesDiskLabels[0]
                    value: root.resourceStats.rootFilesystem ? root.formatBytePair(root.resourceStats.rootFilesystem.usedBytes, root.resourceStats.rootFilesystem.totalBytes) : root.detailStatus(root.resourceStats.rootFilesystemStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesDiskLabels[1]
                    value: root.resourceStats.rootFilesystem ? root.formatBytes(root.resourceStats.rootFilesystem.availableBytes) : root.detailStatus(root.resourceStats.rootFilesystemStatus)
                }

                Row {
                    spacing: Layout.ccGap

                    Text {
                        text: Strings.resourcesLogicalCpus
                        color: root.scheme.muted
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }

                    Text {
                        text: Number.isFinite(root.resourceStats.logicalCpuCount) ? root.resourceStats.logicalCpuCount : root.detailStatus(root.resourceStats.logicalCpuCountStatus)
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }
                }

                Row {
                    spacing: Layout.ccGap

                    Text {
                        text: Strings.resourcesLoadAverage
                        color: root.scheme.muted
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }

                    Text {
                        text: root.resourceStats.loadAverage && Number.isFinite(root.resourceStats.loadAverage.one) && Number.isFinite(root.resourceStats.loadAverage.five) && Number.isFinite(root.resourceStats.loadAverage.fifteen) ? Number(root.resourceStats.loadAverage.one).toFixed(2) + " · " + Number(root.resourceStats.loadAverage.five).toFixed(2) + " · " + Number(root.resourceStats.loadAverage.fifteen).toFixed(2) : root.detailStatus(root.resourceStats.loadAverageStatus)
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
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

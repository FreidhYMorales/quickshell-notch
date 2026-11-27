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

        objectName: "cc-resource-card-" + label
        activeFocusOnTab: true
        spacing: Layout.ccGap

        onActiveFocusChanged: if (activeFocus) {
            const y = mapToItem(resourceViewport.contentItem, 0, 0).y;
            if (y < resourceViewport.contentY)
                resourceViewport.contentY = y;
            else if (y + height > resourceViewport.contentY + resourceViewport.height)
                resourceViewport.contentY = y + height - resourceViewport.height;
        }

        Text {
            text: detail.label
            color: detail.activeFocus ? root.scheme.primary : root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }
        Text {
            text: detail.value
            color: detail.activeFocus ? root.scheme.primary : root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }
    }

    readonly property var scheme: Colours.paletteFor(screen)
    // Defaults to the live service; tests can provide deterministic readings.
    property var resourceStats: SysInfo
    property bool open: false
    property bool keyboardMode: false
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
    onOpenChanged: {
        SysInfo.setControlCenterOpen(root.screen.name, root.open);
        if (open) {
            PowerProfile.refresh();
            if (keyboardMode)
                focusTimer.restart();
        } else {
            keyboardMode = false;
        }
    }
    Component.onDestruction: SysInfo.setControlCenterOpen(root.screen.name, false)
    onWantsKeyboardChanged: if (wantsKeyboard)
        focusTimer.restart()
    onViewChanged: if (open && keyboardMode)
        focusTimer.restart()
    Component.onCompleted: if (open && keyboardMode)
        focusTimer.restart()

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
    function formatRate(bytesPerSecond) {
        return Number.isFinite(bytesPerSecond) && bytesPerSecond >= 0 ? formatBytes(bytesPerSecond) + Strings.resourcesRateSuffix : Strings.resourcesMeasuring;
    }
    function diskActivityRate(propertyName) {
        const status = root.resourceStats.diskActivityStatus;
        if (status && status !== "available")
            return root.detailStatus(status);
        const activity = root.resourceStats.diskActivity;
        if (!activity)
            return root.detailStatus(status);
        const rate = activity[propertyName];
        return Number.isFinite(rate) && rate >= 0 ? root.formatRate(rate) : root.detailStatus(status || "invalid");
    }
    function networkActivityRate(propertyName) {
        const status = root.resourceStats.networkActivityStatus;
        if (status && status !== "available")
            return root.detailStatus(status);
        const activity = root.resourceStats.networkActivity;
        if (!activity)
            return root.detailStatus(status);
        const rate = activity[propertyName];
        return Number.isFinite(rate) && rate >= 0 ? root.formatRate(rate) : root.detailStatus(status || "invalid");
    }
    function detailStatus(status) {
        if (status === "unavailable")
            return Strings.resourcesUnavailable;
        if (status === "invalid")
            return Strings.resourcesInvalid;
        return Strings.resourcesMeasuring;
    }
    function detailValue(value, status, formatter) {
        if (status && status !== "available")
            return detailStatus(status);
        return Number.isFinite(value) ? formatter(value) : detailStatus(status);
    }
    function memoryValue(value, status, formatter) {
        if (root.resourceStats.memoryDetailsStatus && root.resourceStats.memoryDetailsStatus !== "available")
            return root.detailStatus(root.resourceStats.memoryDetailsStatus);
        return root.detailValue(value, status, formatter);
    }
    function memorySwapPair() {
        if (root.resourceStats.memoryDetailsStatus && root.resourceStats.memoryDetailsStatus !== "available")
            return root.detailStatus(root.resourceStats.memoryDetailsStatus);
        const status = root.resourceStats.memorySwapStatus;
        if (status && status !== "available")
            return root.detailStatus(status);
        const details = root.resourceStats.memoryDetails;
        if (Number.isFinite(details.swapUsedKiB) && Number.isFinite(details.swapTotalKiB))
            return root.formatMemoryPair(details.swapUsedKiB, details.swapTotalKiB);
        if (details.swapUsedKiB === null && details.swapTotalKiB === null)
            return root.detailStatus("unavailable");
        return root.detailStatus("invalid");
    }
    function summaryPercent(value, status) {
        if (status && status !== "available")
            return root.detailStatus(status);
        return Number.isFinite(value) ? Math.round(value) + "%" : root.detailStatus(status);
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
            const next = ControlNav.toggleCommand(root.open, root.view, view);
            root.keyboardMode = next.open;
            if (next.open && view === ControlNav.NOTIFICATIONS)
                root.showNotifications();
            else
                root.view = next.view;
            root.open = next.open;
        }
    }

    slotName: "tr"
    Behavior on progress {
        Anim {}
    }
    anchors.left: false
    anchors.right: true
    implicitWidth: Layout.ccWidth
    implicitHeight: Math.min(Layout.ccHeight, (screen ? screen.height : Layout.ccHeight) - 2 * Layout.ccPad)
    wantsKeyboard: root.view === "resources" || (root.open && root.keyboardMode)
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

        FocusScope {
            id: panel

            objectName: "cc-keyboard-scope"
            focus: root.open && root.keyboardMode

            function focusFirst() {
                if (root.rootView && powerRepeater.count > 0)
                    powerRepeater.itemAt(0).forceActiveFocus();
                else if (root.view === "resources")
                    resourceBack.forceActiveFocus();
                else
                    subView.focusFirst();
            }

            Keys.onEscapePressed: {
                if (!root.rootView) {
                    root.view = ControlNav.back();
                    Qt.callLater(panel.focusFirst);
                } else {
                    root.collapse();
                }
            }

            x: Layout.earRadius + Layout.ccPad
            y: Layout.ccPad
            // Both views are built even while hidden, so the panel always
            // knows the root's height (see panelHeight).
            implicitWidth: Math.max(rootView.implicitWidth, subView.width, resourceViewport.width)
            implicitHeight: ControlNav.panelHeight(root.view, rootView.implicitHeight, Math.max(subView.height, resourceViewport.height))

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
                                status: root.resourceStats.cpuStatus,
                                icon: Strings.glyphCpu
                            },
                            {
                                label: Strings.resourcesRam,
                                value: root.resourceStats.ram,
                                status: root.resourceStats.ramStatus,
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
                                    text: root.summaryPercent(resourceMetric.modelData.value, resourceMetric.modelData.status)
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
                            id: powerRepeater

                            model: PowerMenu.ACTIONS

                            Text {
                                id: powerIcon

                                required property string modelData

                                objectName: "cc-power-" + modelData
                                width: Layout.ccTile
                                height: Layout.ccTile
                                activeFocusOnTab: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: Strings.powerIcons[modelData]
                                color: powerHover.hovered || activeFocus ? root.scheme.primary : root.scheme.onSurface
                                scale: powerHover.hovered || activeFocus ? Layout.powerSelectedScale : 1
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

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                        event.accepted = true;
                                        if (!event.isAutoRepeat)
                                            root.powerClicked(powerIcon.modelData);
                                    }
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

            Flickable {
                id: resourceViewport

                objectName: "cc-resource-grid-viewport"
                visible: root.view === "resources"
                width: resourceView.implicitWidth
                height: Math.min(Layout.ccListHeight, Math.max(0, root.height - 2 * Layout.ccPad - Layout.earRadius - Layout.ccGap - resourceHeader.height))
                contentWidth: width
                contentHeight: resourceView.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true
            }

            Column {
                id: resourceView

                visible: root.view === "resources"
                focus: visible
                Keys.onEscapePressed: root.view = ControlNav.back()
                spacing: Layout.ccGap
                parent: resourceViewport
                width: resourceViewport.width

                Row {
                    id: resourceHeader
                    spacing: Layout.ccGap

                    Item {
                        id: resourceBack
                        objectName: "cc-resource-back"
                        width: Layout.ccClearButton
                        height: width
                        activeFocusOnTab: true

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: backHover.hovered || resourceBack.activeFocus ? root.scheme.primary : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Strings.glyphChevronLeft
                            color: backHover.hovered || resourceBack.activeFocus ? Colours.background : root.scheme.onSurface
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

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                event.accepted = true;
                                root.view = ControlNav.back();
                            }
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

                ResourceDetailRow {
                    label: Strings.resourcesCpu
                    value: root.detailValue(root.resourceStats.cpu, root.resourceStats.cpuStatus, value => Math.round(value) + "%")
                }

                ResourceDetailRow {
                    label: Strings.resourcesRam
                    value: root.detailValue(root.resourceStats.ram, root.resourceStats.ramStatus, value => Math.round(value) + "%")
                }

                ResourceDetailRow {
                    label: Strings.resourcesMemoryLabels[0]
                    value: root.resourceStats.memoryDetails ? root.memoryValue(root.resourceStats.memoryDetails.usedKiB, root.resourceStats.memoryDetailsStatus, value => root.formatMemoryPair(value, root.resourceStats.memoryDetails.totalKiB)) : root.detailStatus(root.resourceStats.memoryDetailsStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesMemoryLabels[1]
                    value: root.resourceStats.memoryDetails ? root.memoryValue(root.resourceStats.memoryDetails.availableKiB, root.resourceStats.memoryDetailsStatus, value => root.formatMemory(value)) : root.detailStatus(root.resourceStats.memoryDetailsStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesMemoryLabels[2]
                    value: root.resourceStats.memoryDetails ? root.memorySwapPair() : root.detailStatus(root.resourceStats.memoryDetailsStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesDiskLabels[0]
                    value: root.resourceStats.rootFilesystem ? root.detailValue(root.resourceStats.rootFilesystem.usedBytes, root.resourceStats.rootFilesystemStatus, value => root.formatBytePair(value, root.resourceStats.rootFilesystem.totalBytes)) : root.detailStatus(root.resourceStats.rootFilesystemStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesDiskLabels[1]
                    value: root.resourceStats.rootFilesystem ? root.detailValue(root.resourceStats.rootFilesystem.availableBytes, root.resourceStats.rootFilesystemStatus, value => root.formatBytes(value)) : root.detailStatus(root.resourceStats.rootFilesystemStatus)
                }

                ResourceDetailRow {
                    label: Strings.resourcesDiskActivityLabels[0]
                    value: root.diskActivityRate("readBytesPerSecond")
                }

                ResourceDetailRow {
                    label: Strings.resourcesDiskActivityLabels[1]
                    value: root.diskActivityRate("writeBytesPerSecond")
                }

                ResourceDetailRow {
                    label: Strings.resourcesNetworkLabels[0]
                    value: root.networkActivityRate("receiveBytesPerSecond")
                }

                ResourceDetailRow {
                    label: Strings.resourcesNetworkLabels[1]
                    value: root.networkActivityRate("transmitBytesPerSecond")
                }

                ResourceDetailRow {
                    label: Strings.resourcesLogicalCpus
                    value: root.detailValue(root.resourceStats.logicalCpuCount, root.resourceStats.logicalCpuCountStatus, value => value)
                }

                ResourceDetailRow {
                    label: Strings.resourcesLoadAverage
                    value: root.resourceStats.loadAverageStatus && root.resourceStats.loadAverageStatus !== "available" ? root.detailStatus(root.resourceStats.loadAverageStatus) : root.resourceStats.loadAverage && Number.isFinite(root.resourceStats.loadAverage.one) && Number.isFinite(root.resourceStats.loadAverage.five) && Number.isFinite(root.resourceStats.loadAverage.fifteen) ? Number(root.resourceStats.loadAverage.one).toFixed(2) + " · " + Number(root.resourceStats.loadAverage.five).toFixed(2) + " · " + Number(root.resourceStats.loadAverage.fifteen).toFixed(2) : root.detailStatus(root.resourceStats.loadAverageStatus || "invalid")
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
                if (!root.open) {
                    root.keyboardMode = false;
                    root.view = ControlNav.initialView();
                }
                root.open = true;
            } else if (ControlNav.closeOnLeave(root.view) === "now") {
                root.collapse();
            } else {
                leaveTimer.restart();
            }
        }
    }

    Timer {
        id: focusTimer

        interval: 100
        repeat: false
        onTriggered: if (root.open && root.keyboardMode)
            panel.focusFirst()
    }

    Timer {
        id: leaveTimer

        interval: Timings.ccLeave
        onTriggered: root.collapse()
    }
}

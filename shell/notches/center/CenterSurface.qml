import QtQuick
import "../../components"
import "../../config"
import "../../logic/centerLayout.mjs" as CenterLayout
import "../../services"

// Centre notch (slot c), one per monitor. The view comes from the shared
// CenterStore. One shape item is both the input mask and the hover zone; its
// width follows the battery layer (symmetric, so the clock stays put) when
// idle, and the player presence when expanded; it animates between the two.
NotchSurface {
    id: root

    readonly property var view: CenterStore.viewFor(screen.name)
    readonly property int idleW: CenterLayout.idleWidth({
        base: idle.baseWidth,
        side: idle.sideNeed,
        layer: idle.batteryLayer,
        dot: idle.dotExtent,
        max: slot.width
    })
    readonly property bool toast: view.mode === "toast"
    readonly property var size: toast ? CenterLayout.toastShape({
        expanded: view.toast.expanded,
        widths: {
            compact: Layout.toastWidth,
            expanded: Layout.toastExpandedWidth
        },
        heights: {
            compact: Layout.idleHeight,
            expanded: Layout.toastExpandedHeight
        },
        max: slot.width
    }) : CenterLayout.shapeFor(view.mode, {
        idle: idleW,
        expanded: CenterLayout.expandedWidth({
            hasPlayer: Mpris.hasPlayer,
            full: Layout.expandedWidth,
            clockOnly: Layout.expandedClockWidth,
            mark: expandedView.markExtent,
            max: slot.width
        }),
        power: Layout.powerWidth,
        launcher: Layout.launcherWidth
    }, {
        idle: Layout.idleHeight,
        expanded: Layout.expandedHeight,
        power: Layout.powerHeight,
        launcher: Layout.launcherHeight
    })
    readonly property bool expanded: view.mode === "expanded"
    readonly property bool power: view.mode === "power"
    readonly property bool launcher: view.mode === "launcher"

    slotName: "c"
    wantsKeyboard: view.keyboardFocus === "exclusive"
    // Only the visible shape takes input; clicks beside it pass through.
    maskItem: shape

    Item {
        id: shape

        width: root.shown ? root.size.width : 0
        height: root.size.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        clip: true

        // Keeps the zone hovered while a child (power icons) takes the hover.
        HoverHandler {
            id: shapeHover
        }

        Behavior on width {
            Anim {}
        }

        Behavior on height {
            Anim {}
        }

        CenterIdle {
            id: idle

            anchors.fill: parent
            visible: !root.expanded && !root.toast && !root.power && !root.launcher
            screen: root.screen
            view: root.view
        }

        CenterToast {
            anchors.fill: parent
            visible: root.toast
            screen: root.screen
            expanded: root.toast && root.view.toast.expanded
        }

        CenterPower {
            anchors.fill: parent
            visible: root.power
            screen: root.screen
            view: root.view
        }

        CenterLauncher {
            anchors.fill: parent
            visible: root.launcher
            screen: root.screen
            view: root.view
        }

        CenterExpanded {
            id: expandedView

            anchors.fill: parent
            visible: root.expanded
            screen: root.screen
        }
    }

    // Below the content so the power icons get their own hover.
    NotchZone {
        z: -1
        anchors.fill: shape
        alsoHovered: shapeHover.hovered
        onHoverChanged: on => CenterStore.dispatch({
                type: "Hover",
                monitor: root.screen.name,
                on: on
            })
    }
}

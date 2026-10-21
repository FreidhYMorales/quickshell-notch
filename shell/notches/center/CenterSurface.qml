import QtQuick
import "../../components"
import "../../config"
import "../../logic/centerLayout.mjs" as CenterLayout
import "../../services"

// Centre notch (slot c), one per monitor. The view comes from the shared
// CenterStore. One shape item is both the input mask and the hover zone; its
// width follows the battery layer (symmetric, so the clock stays put). The
// expanded shape has no content yet, so both modes use the idle size until
// the expanded views arrive.
NotchSurface {
    id: root

    readonly property var view: CenterStore.viewFor(screen.name)
    readonly property int idleW: CenterLayout.idleWidth({
        base: Layout.idleWidth,
        side: Layout.batterySide,
        layer: Battery.layer,
        max: slot.width
    })
    readonly property var size: CenterLayout.shapeFor(view.mode, {
        idle: idleW,
        expanded: idleW
    }, {
        idle: Layout.idleHeight,
        expanded: Layout.idleHeight
    })

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

        Behavior on width {
            Anim {}
        }

        CenterIdle {
            anchors.fill: parent
            screen: root.screen
            view: root.view
        }
    }

    NotchZone {
        anchors.fill: shape
        onHoverChanged: on => CenterStore.dispatch({
                type: "Hover",
                monitor: root.screen.name,
                on: on
            })
    }
}

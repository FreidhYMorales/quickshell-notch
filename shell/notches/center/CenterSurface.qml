import QtQuick
import "../../components"
import "../../config"

// Centre notch (slot c), one per monitor. The view comes from the shared
// CenterStore. Hover drives Expanded in the reducer, but Expanded has no
// content yet, so every mode still paints the idle shape.
NotchSurface {
    id: root

    readonly property var view: CenterStore.viewFor(screen.name)

    slotName: "c"
    wantsKeyboard: view.keyboardFocus === "exclusive"

    CenterIdle {
        anchors.fill: parent
        screen: root.screen
    }

    NotchZone {
        anchors.fill: parent
        onHoverChanged: on => CenterStore.dispatch({
                type: "Hover",
                monitor: root.screen.name,
                on: on
            })
    }
}

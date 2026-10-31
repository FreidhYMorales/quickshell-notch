import QtQuick
import "../config"

// Hover hitbox. `hoverChanged` fires only after the state has been stable:
// `openDelay` before reporting hover on (so a pass-by does not open the
// notch), Timings.hoverDebounce before reporting hover off. `alsoHovered`
// counts as hover too: a surface whose buttons take the hover passes the
// hover of the buttons' ancestor here.
Item {
    id: root

    property bool alsoHovered: false
    readonly property bool hovered: handler.hovered || alsoHovered
    property int openDelay: Timings.hoverOpen

    signal hoverChanged(bool on)

    onHoveredChanged: debounce.restart()

    HoverHandler {
        id: handler
    }

    Timer {
        id: debounce

        interval: root.hovered ? root.openDelay : Timings.hoverDebounce
        onTriggered: root.hoverChanged(root.hovered)
    }
}

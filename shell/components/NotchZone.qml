import QtQuick
import "../config"

// Hover hitbox. `hoverChanged` fires only after the state has been stable:
// `openDelay` before reporting hover on (so a pass-by does not open the
// notch), Timings.hoverDebounce before reporting hover off.
Item {
    id: root

    readonly property bool hovered: handler.hovered
    property int openDelay: Timings.hoverOpen

    signal hoverChanged(bool on)

    HoverHandler {
        id: handler
    }

    Timer {
        id: debounce

        interval: handler.hovered ? root.openDelay : Timings.hoverDebounce
        onTriggered: root.hoverChanged(handler.hovered)
    }

    Connections {
        function onHoveredChanged() {
            debounce.restart();
        }

        target: handler
    }
}

import QtQuick
import "../config"

// Hover hitbox. `hoverChanged` fires only after the state has been stable
// for Timings.hoverDebounce, so edge flicker does not toggle the notch.
Item {
    id: root

    readonly property bool hovered: handler.hovered

    signal hoverChanged(bool on)

    HoverHandler {
        id: handler
    }

    Timer {
        id: debounce

        interval: Timings.hoverDebounce
        onTriggered: root.hoverChanged(handler.hovered)
    }

    Connections {
        function onHoveredChanged() {
            debounce.restart();
        }

        target: handler
    }
}

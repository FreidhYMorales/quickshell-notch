import QtQuick
import "../../components"
import "../../config"

// Placeholder: drawn only with Flags.showPlaceholders; no mask area otherwise.
NotchSurface {
    id: root

    shown: Flags.showPlaceholders
    slotName: "tl"
    CornerEarShape {
        anchors.fill: parent
        anchor: "topLeft"
    }

    Text {
        anchors.centerIn: parent
        text: Strings.workspaces
        color: Colours.paletteFor(root.screen).muted
        font.family: Fonts.family
    }
}

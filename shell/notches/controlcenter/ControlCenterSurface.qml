import QtQuick
import "../../components"
import "../../config"

// Placeholder: drawn only with Flags.showPlaceholders; no mask area otherwise.
NotchSurface {
    id: root

    shown: Flags.showPlaceholders
    slotName: "tr"
    CornerEarShape {
        anchors.fill: parent
        anchor: "topRight"
    }

    Text {
        anchors.centerIn: parent
        text: Strings.controlCenter
        color: Colours.paletteFor(root.screen).muted
        font.family: Fonts.family
    }
}

import QtQuick
import "../../components"
import "../../config"

// Placeholder for the brightness (bl) and volume (vr) OSDs: drawn only with
// Flags.showPlaceholders; no mask area otherwise.
NotchSurface {
    id: root

    property string label: ""

    shown: Flags.showPlaceholders

    NotchEarShape {
        anchors.fill: parent
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: Colours.paletteFor(root.screen).muted
        font.family: Fonts.family
    }
}

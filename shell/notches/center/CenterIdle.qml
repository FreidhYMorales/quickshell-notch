import QtQuick
import "../../components"
import "../../config"

// Idle centre notch: pure black with concave top ears. The text is a static
// placeholder until real data (clock, media) arrives in later phases.
Item {
    id: root

    property var screen: null

    NotchEarShape {
        anchors.fill: parent
    }

    Text {
        anchors.centerIn: parent
        text: Strings.center
        color: Colours.paletteFor(root.screen).muted
        font.family: Fonts.family
    }
}

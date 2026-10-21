import QtQuick
import "../../components"
import "../../config"

// Idle centre notch: pure black with concave top ears, Layout.idleWidth wide
// and centred in its parent (the fixed-size surface). The text is a static
// placeholder until real data (clock, media) arrives in later phases.
Item {
    id: root

    property var screen: null
    property bool shown: true

    width: shown ? Math.min(Layout.idleWidth, parent.width) : 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.bottom: parent.bottom

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

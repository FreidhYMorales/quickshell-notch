import QtQuick
import "../../config"

// One round toggle button, icon only: solid primary when on, a translucent
// primary when off. Left click toggles, right click opens the tile's detail.
Rectangle {
    id: root

    property var scheme
    property bool on: false
    property string glyph: ""

    signal toggled
    signal detailRequested

    width: Layout.ccTile
    height: Layout.ccTile
    radius: Layout.ccTile / 2
    color: {
        const p = Qt.color(scheme.primary);
        return on ? p : Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
    }

    Behavior on color {
        ColorAnimation {
            duration: Timings.animFast
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.on ? Colours.background : root.scheme.onSurface
        font.family: Fonts.family
        font.pixelSize: Fonts.control
    }

    // The cursor lives on a HoverHandler: a MouseArea with cursorShape takes
    // the hover and the control center would collapse.
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.detailRequested();
            else
                root.toggled();
        }
    }
}

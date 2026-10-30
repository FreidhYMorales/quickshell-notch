import QtQuick
import "../../config"

// One toggle tile: lit (primary) when on, card colour when off.
// Left click toggles, right click opens the tile's detail.
Rectangle {
    id: root

    property var scheme
    property color card
    property bool on: false
    property string glyph: ""
    property string label: ""

    signal toggled
    signal detailRequested

    width: Layout.ccTileWidth
    height: Layout.ccTileHeight
    radius: Layout.cardRadius
    color: on ? scheme.primary : card

    Column {
        anchors.centerIn: parent

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.glyph
            color: root.on ? Colours.background : root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.control
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.on ? Colours.background : root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.small
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.detailRequested();
            else
                root.toggled();
        }
    }
}

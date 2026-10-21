import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Expanded centre notch content: media column on the left (only with a
// player) and the clock card on the right. Replaces the idle row.
Item {
    id: root

    property var screen: null

    readonly property var scheme: Colours.paletteFor(screen)

    NotchEarShape {
        anchors.fill: parent
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Layout.earRadius + Layout.expandedPad
        anchors.rightMargin: Layout.earRadius + Layout.expandedPad
        anchors.topMargin: Layout.expandedPad
        anchors.bottomMargin: Layout.expandedPad

        CenterMedia {
            anchors.left: parent.left
            anchors.right: card.left
            anchors.rightMargin: Layout.expandedGap
            anchors.verticalCenter: parent.verticalCenter
            visible: Mpris.hasPlayer
            scheme: root.scheme
        }

        CenterClockCard {
            id: card

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: Mpris.hasPlayer ? Layout.clockCardWidth : parent.width
            scheme: root.scheme
            cardColor: Colours.cardFor(root.screen)
        }
    }
}

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
    // What a visible `!` adds on each side (CenterLayout.expandedWidth).
    readonly property int markExtent: mark.visible ? Layout.expandedGap + mark.implicitWidth : 0

    NotchEarShape {
        anchors.fill: parent
    }

    Item {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Layout.earRadius + Layout.expandedPad + root.markExtent
        anchors.rightMargin: Layout.earRadius + Layout.expandedPad + root.markExtent
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

    // Waiting criticals: the `!` gets its own column right of the card.
    CriticalMark {
        id: mark

        anchors.left: content.right
        anchors.leftMargin: Layout.expandedGap
        anchors.top: content.top
        visible: Notifs.pinned.length > 0
        onClicked: Notifs.reopen()
    }
}

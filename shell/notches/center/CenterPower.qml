pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../logic/powerMenu.mjs" as PowerMenu

// Power menu in the centre notch: one row of action icons (the selected one
// highlighted) over a bar that fills while a session action is held.
Item {
    id: root

    property var screen: null
    property var view: ({})

    readonly property var scheme: Colours.paletteFor(screen)
    readonly property string selected: view.sub ?? PowerMenu.ACTIONS[0]
    readonly property bool holding: view.hold != null

    NotchEarShape {
        anchors.fill: parent
    }

    Row {
        anchors.centerIn: parent
        spacing: Layout.expandedPad * 2

        Repeater {
            model: PowerMenu.ACTIONS

            Text {
                required property string modelData

                text: Strings.powerIcons[modelData]
                color: modelData === root.selected ? root.scheme.primary : root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.control
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Layout.earRadius
        anchors.bottomMargin: Layout.expandedPad
        height: Layout.powerBarHeight
        width: (parent.width - 2 * Layout.earRadius) * progress
        visible: root.holding
        color: root.scheme.primary

        property real progress: 0

        // Restarts from empty each time a hold begins; the store's timer decides.
        NumberAnimation on progress {
            running: root.holding
            from: 0
            to: 1
            duration: Timings.holdConfirm
        }
    }
}

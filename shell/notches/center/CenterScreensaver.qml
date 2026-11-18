pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"

// Screensaver sub-view of the launcher: the screensaver, lock and suspend
// minutes the idle chain uses.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property var minutes: [Idle.timeouts.screensaver, Idle.timeouts.lock, Idle.timeouts.suspend]

    signal back

    implicitHeight: Layout.screensaverViewHeight

    Column {
        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            width: parent.width
            text: Strings.screensaverTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        Row {
            id: stages

            width: parent.width
            spacing: Layout.launcherGap

            Repeater {
                model: Strings.idleStageNames

                Column {
                    id: stage

                    required property string modelData
                    required property int index
                    readonly property int value: root.minutes[index]

                    width: (stages.width - 2 * stages.spacing) / 3
                    spacing: Layout.launcherGap

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: stage.modelData
                        color: root.scheme.muted
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: stage.value > 0 ? Strings.idleMinutes.arg(stage.value) : Strings.idleOff
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem
                    }
                }
            }
        }
    }
}

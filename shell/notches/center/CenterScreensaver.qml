pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/idleState.mjs" as IdleState

// Screensaver sub-view of the launcher: the screensaver, lock and suspend
// minutes the idle chain uses.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property var stageKeys: ["screensaver", "lock", "suspend"]
    readonly property var minutes: [Idle.timeouts.screensaver, Idle.timeouts.lock, Idle.timeouts.suspend]

    signal back

    Keys.onEscapePressed: back()

    // Grows with the picker when the switch is off.
    implicitHeight: content.implicitHeight

    Column {
        id: content

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
                    readonly property string key: root.stageKeys[index]

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

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Layout.launcherGap

                        Text {
                            objectName: "idle-" + stage.key + "-less"
                            text: Strings.idleLess
                            color: root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.launcherItem

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Idle.setMinutes(stage.key, IdleState.stepMinutes(stage.value, -1))
                            }
                        }

                        Text {
                            objectName: "idle-" + stage.key + "-value"
                            text: stage.value > 0 ? Strings.idleMinutes.arg(stage.value) : Strings.idleOff
                            color: root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.launcherItem
                        }

                        Text {
                            objectName: "idle-" + stage.key + "-more"
                            text: Strings.idleMore
                            color: root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.launcherItem

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Idle.setMinutes(stage.key, IdleState.stepMinutes(stage.value, 1))
                            }
                        }
                    }
                }
            }
        }

        Text {
            objectName: "screensaver-same"
            text: (Idle.choice.sameAsDesktop ? Strings.idleSwitchOn : Strings.idleSwitchOff) + "  " + Strings.idleSameAsDesktop
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Idle.setSameAsDesktop(!Idle.choice.sameAsDesktop)
            }
        }

        // The screensaver's own wallpaper, only while the switch is off.
        ListView {
            objectName: "screensaver-picker"
            visible: !Idle.choice.sameAsDesktop
            width: parent.width
            height: Layout.screensaverPickerHeight
            orientation: ListView.Horizontal
            spacing: Layout.launcherGap
            clip: true
            model: Wallpapers.entries

            delegate: Item {
                id: card

                required property var modelData
                readonly property bool chosen: modelData.path === Idle.choice.path

                objectName: "screensaver-wallpaper-" + modelData.name
                width: Layout.screensaverPickerWidth
                height: Layout.screensaverPickerHeight

                Image {
                    anchors.fill: parent
                    source: card.modelData.video ? Wallpapers.thumbnailFor(card.modelData.path) : "file://" + card.modelData.path
                    sourceSize.height: Layout.screensaverPickerHeight
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: card.chosen ? Layout.screensaverChosenBorder : 0
                    border.color: root.scheme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Idle.setScreensaverPath(card.modelData.path)
                }
            }
        }
    }
}

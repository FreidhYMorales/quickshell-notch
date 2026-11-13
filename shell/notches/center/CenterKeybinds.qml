pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/keybinds.mjs" as KeybindsLogic

// Keybinds sub-view of the launcher: the live Hyprland bind registry, one row
// per shortcut with its key label and description.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)
    property string query: ""
    readonly property var rows: KeybindsLogic.filterKeybinds(Keybinds.rows, query)

    signal back

    implicitHeight: Layout.keybindsViewHeight

    Column {
        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            id: title

            width: parent.width
            text: Strings.keybindsTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        TextInput {
            id: field

            objectName: "keybinds-field"
            width: parent.width
            focus: root.visible
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
            // Each opening starts from the whole list.
            onVisibleChanged: if (visible) {
                clear();
                forceActiveFocus();
            }
            onTextChanged: root.query = text
        }

        Text {
            id: noMatches

            width: parent.width
            visible: Keybinds.available && root.rows.length === 0
            text: Strings.noMatches
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        ListView {
            id: list

            width: parent.width
            height: parent.height - title.height - field.height - noMatches.height - Layout.launcherGap * 3
            visible: Keybinds.available
            model: root.rows
            clip: true

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                objectName: "keybinds-row-" + index
                width: list.width
                height: Layout.keybindsRowHeight

                Rectangle {
                    id: pill

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: keyText.implicitWidth + 2 * Layout.keybindsPillPad
                    height: Layout.keybindsPillHeight
                    radius: height / 2
                    color: Colours.cardFor(root.screen)

                    Text {
                        id: keyText

                        anchors.centerIn: parent
                        text: row.modelData.keys
                        color: root.scheme.primary
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem
                    }
                }

                Text {
                    anchors {
                        left: pill.right
                        leftMargin: Layout.launcherGap
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: row.modelData.description
                    elide: Text.ElideRight
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.launcherItem
                }
            }
        }
        Text {
            id: unavailable

            width: parent.width
            visible: !Keybinds.available
            text: Strings.keybindsUnavailable
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/theme.mjs" as ThemeLogic

// Theme sub-view of the launcher: the nine matugen scheme modes, the active
// one marked and a preview placeholder until the swatch pipeline lands.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)

    signal back
    signal applied

    implicitHeight: Layout.themeViewHeight

    function choose(index) {
        const mode = ThemeLogic.MODES[index];
        if (!mode)
            return;
        Theme.select(mode);
        applied();
    }

    Column {
        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            width: parent.width
            text: Strings.themeTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        ListView {
            id: list

            width: parent.width
            height: parent.height - Layout.launcherRowHeight - Layout.launcherGap * 2
            model: ThemeLogic.MODES
            clip: true

            delegate: Item {
                id: row

                required property string modelData
                required property int index
                readonly property bool active: modelData === Theme.mode

                objectName: "theme-row-" + modelData
                width: list.width
                height: Layout.themeRowHeight

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Layout.launcherGap

                    Rectangle {
                        objectName: "theme-preview"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !Theme.previews[modelData]
                        width: Layout.themePreview
                        height: Layout.themePreview
                        radius: width / 2
                        color: root.scheme.muted
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.themeModeNames[modelData] ?? modelData
                        color: row.active ? root.scheme.primary : root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem
                    }

                    Text {
                        objectName: "theme-active-" + modelData
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.active
                        text: Strings.themeActiveMark
                        color: root.scheme.primary
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem
                    }
                }

                TapHandler {
                    onTapped: root.choose(row.index)
                }
            }
        }

        Text {
            width: parent.width
            text: Strings.themeHint
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }
    }
}

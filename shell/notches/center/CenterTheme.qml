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

    // The row the arrows move over; starts on the active mode.
    property int currentIndex: 0

    function resetCursor() {
        const index = ThemeLogic.MODES.indexOf(Theme.mode);
        currentIndex = index < 0 ? 0 : index;
        list.positionViewAtIndex(currentIndex, ListView.Contain);
    }

    Component.onCompleted: {
        if (!visible)
            return;
        resetCursor();
        Theme.generatePreviews(screen.name);
    }
    onVisibleChanged: {
        if (!visible)
            return;
        resetCursor();
        Theme.generatePreviews(screen.name);
    }

    function choose(index) {
        const mode = ThemeLogic.MODES[index];
        if (!mode)
            return;
        Theme.select(mode);
        applied();
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            back();
            break;
        case Qt.Key_Up:
        case Qt.Key_K:
            root.currentIndex = Math.max(0, root.currentIndex - 1);
            list.positionViewAtIndex(root.currentIndex, ListView.Contain);
            break;
        case Qt.Key_Down:
        case Qt.Key_J:
            root.currentIndex = Math.min(ThemeLogic.MODES.length - 1, root.currentIndex + 1);
            list.positionViewAtIndex(root.currentIndex, ListView.Contain);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.choose(root.currentIndex);
            break;
        default:
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Column {
        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            id: title

            width: parent.width
            text: Strings.themeTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        ListView {
            id: list

            width: parent.width
            height: parent.height - title.height - hint.height - Layout.launcherGap * 2
            model: ThemeLogic.MODES
            clip: true

            delegate: Item {
                id: row

                required property string modelData
                required property int index
                readonly property bool active: modelData === Theme.mode
                readonly property bool current: index === root.currentIndex
                readonly property var preview: Theme.previewFor(root.screen.name, modelData)

                objectName: "theme-row-" + modelData
                width: list.width
                height: Layout.themeRowHeight

                Rectangle {
                    anchors.fill: parent
                    color: row.current ? Colours.cardFor(root.screen) : "transparent"
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Layout.launcherGap

                    Rectangle {
                        objectName: "theme-preview"
                        anchors.verticalCenter: parent.verticalCenter
                        width: Layout.themePreview
                        height: Layout.themePreview
                        radius: width / 2
                        color: row.preview ? row.preview.primary : root.scheme.muted
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
            id: hint

            width: parent.width
            text: Strings.themeHint
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../services"
import "../../logic/theme.mjs" as ThemeLogic

// Theme sub-view of the launcher: the nine matugen scheme modes, the active
// one marked and a preview placeholder until the swatch pipeline lands.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)
    // Fill of the highlighted row and the switch track, as light as a
    // notification row so both stand out from the black notch.
    readonly property color raised: {
        const p = Qt.color(scheme.primary);
        return Qt.rgba(p.r, p.g, p.b, Colours.raisedAlpha);
    }

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

    // Only the apps follow the switch; the notch stays dark.
    function toggleVariant() {
        Theme.setVariant(Theme.variant === "light" ? "dark" : "light");
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            back();
            break;
        case Qt.Key_Tab:
            root.toggleVariant();
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

        Item {
            id: header

            width: parent.width
            height: Math.max(title.implicitHeight, Layout.themeSwitchHeight)

            Text {
                id: title

                anchors.verticalCenter: parent.verticalCenter
                text: Strings.themeTitle
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            // Knob on the left is Dark, on the right Light.
            Rectangle {
                id: track

                readonly property bool light: Theme.variant === "light"

                objectName: "theme-variant-switch"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.themeSwitchWidth
                height: Layout.themeSwitchHeight
                radius: height / 2
                color: root.raised
                border.width: Layout.themeSwitchBorder
                border.color: root.raised

                Rectangle {
                    objectName: "theme-variant-knob"
                    anchors.verticalCenter: parent.verticalCenter
                    width: track.height - Layout.themeSwitchInset * 2
                    height: width
                    radius: width / 2
                    x: track.light ? track.width - width - Layout.themeSwitchInset : Layout.themeSwitchInset
                    color: root.scheme.primary

                    Behavior on x {
                        Anim {}
                    }

                    Text {
                        objectName: "theme-variant-icon"
                        anchors.centerIn: parent
                        text: track.light ? Strings.themeLight : Strings.themeDark
                        color: Colours.background
                        font.family: Fonts.family
                        font.pixelSize: Fonts.body
                    }
                }

                TapHandler {
                    onTapped: root.toggleVariant()
                }
            }
        }

        ListView {
            id: list

            width: parent.width
            height: parent.height - header.height - hint.height - Layout.launcherGap * 2
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
                    color: row.current ? root.raised : "transparent"
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

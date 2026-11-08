pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/themeState.mjs" as ThemeState

// Live preview; Escape restores the committed appearance without disk writes.
Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property var presets: ThemeState.PRESETS
    readonly property int selectedIndex: Math.max(0, presets.findIndex(p => p.id === Theme.current.preset))

    signal back
    signal applied

    implicitHeight: 316
    focus: visible
    onVisibleChanged: if (visible)
        forceActiveFocus()

    function move(step) {
        const next = (selectedIndex + step + presets.length) % presets.length;
        Theme.setPreset(presets[next].id);
    }

    function confirm() {
        Theme.commit();
        applied();
    }

    function cancel() {
        Theme.cancel();
        back();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            root.move(-1);
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            root.move(1);
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            Theme.setMode(Theme.current.mode === "dark" ? "light" : "dark");
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.confirm();
        } else if (event.key === Qt.Key_Escape) {
            root.cancel();
        } else {
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Column {
        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            text: Strings.themeTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        Row {
            width: parent.width
            spacing: Layout.launcherGap

            Repeater {
                model: ThemeState.MODES

                delegate: Rectangle {
                    id: modeButton
                    required property string modelData
                    readonly property bool selected: Theme.current.mode === modelData

                    width: (root.width - Layout.launcherGap) / 2
                    height: 38
                    radius: Layout.cardRadius
                    color: selected ? root.scheme.primary : Colours.cardFor(root.screen)

                    Text {
                        anchors.centerIn: parent
                        text: modeButton.modelData === "dark" ? Strings.themeDark : Strings.themeLight
                        color: modeButton.selected ? Colours.background : root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem
                    }

                    TapHandler {
                        onTapped: Theme.setMode(modeButton.modelData)
                    }
                }
            }
        }

        Text {
            text: Strings.themePaletteTitle
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        Row {
            spacing: Layout.launcherGap

            Repeater {
                model: root.presets

                delegate: Rectangle {
                    id: swatch
                    required property var modelData
                    readonly property bool selected: Theme.current.preset === modelData.id

                    width: (root.width - 4 * Layout.launcherGap) / 5
                    height: 76
                    radius: Layout.cardRadius
                    color: Colours.cardFor(root.screen)
                    border.width: selected ? 2 : 0
                    border.color: root.scheme.primary

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 9
                        width: 34
                        height: 34
                        radius: 17
                        color: swatch.modelData.id === "auto" ? root.scheme.primary : swatch.modelData[Theme.current.mode]
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        text: swatch.modelData.name
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.launcherItem - 3
                    }

                    TapHandler {
                        onTapped: Theme.setPreset(swatch.modelData.id)
                    }
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: Strings.themeHint
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem - 2
        }

        Row {
            spacing: Layout.launcherGap

            Rectangle {
                width: 150
                height: 34
                radius: Layout.cardRadius
                color: root.scheme.primary

                Text {
                    anchors.centerIn: parent
                    text: Strings.themeApply
                    color: Colours.background
                    font.family: Fonts.family
                    font.pixelSize: Fonts.launcherItem
                }
                TapHandler {
                    onTapped: root.confirm()
                }
            }

            Rectangle {
                width: 150
                height: 34
                radius: Layout.cardRadius
                color: Colours.cardFor(root.screen)

                Text {
                    anchors.centerIn: parent
                    text: Strings.themeCancel
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.launcherItem
                }
                TapHandler {
                    onTapped: root.cancel()
                }
            }
        }
    }
}

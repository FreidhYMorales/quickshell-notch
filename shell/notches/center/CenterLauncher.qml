pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../components"
import "../../config"
import "../../services"
import "../../logic/launcherSearch.mjs" as LauncherSearch

// App launcher in the centre notch: a search field over the ranked results,
// the selected one highlighted.
Item {
    id: root

    property var screen: null
    property var view: ({})

    readonly property var scheme: Colours.paletteFor(screen)
    readonly property bool wallpaperMode: view.sub === "wallpaper"
    readonly property bool themeMode: view.sub === "theme"
    readonly property bool keybindsMode: view.sub === "keybinds"
    readonly property bool webappMode: view.sub === "webapp"
    readonly property bool commandMode: (view.query ?? "").startsWith(">")
    readonly property var results: commandMode ? LauncherSearch.rankApps(Strings.launcherCommands, (view.query ?? "").slice(1)) : LauncherSearch.rankApps(Apps.list, view.query ?? "")

    function send(event) {
        CenterStore.dispatch(event);
    }

    function move(step) {
        send({
            type: "LauncherMove",
            step: step,
            count: results.length
        });
    }

    // Null when there are no results: the reducer then does nothing.
    function launch(index) {
        if (commandMode) {
            if (results[index]?.name === Strings.wallpaperTitle) {
                Wallpapers.begin(screen.name);
                send({
                    type: "WallpaperOpen"
                });
            } else if (results[index]?.name === Strings.themeTitle) {
                send({
                    type: "ThemeOpen"
                });
            } else if (results[index]?.name === Strings.keybindsTitle) {
                Keybinds.refresh();
                send({
                    type: "KeybindsOpen"
                });
            } else if (results[index]?.name === Strings.webappTitle) {
                send({
                    type: "WebappOpen"
                });
            }
            return;
        }
        send({
            type: "LauncherActivate",
            appId: results[index]?.id ?? null
        });
    }

    // The same padding on every side of the content (inside the ears).
    implicitHeight: (root.themeMode ? themeView.implicitHeight : root.keybindsMode ? keybindsView.implicitHeight : root.webappMode ? webappView.implicitHeight : root.wallpaperMode ? wallpaperView.implicitHeight : column.implicitHeight) + 2 * Layout.launcherPad

    NotchEarShape {
        anchors.fill: parent
    }

    CenterWallpaper {
        id: wallpaperView
        visible: root.wallpaperMode
        screen: root.screen
        x: Layout.earRadius + Layout.launcherPad
        y: Layout.launcherPad
        width: parent.width - 2 * (Layout.earRadius + Layout.launcherPad)
        focus: root.wallpaperMode
        onVisibleChanged: if (visible)
            forceActiveFocus()
        onBack: root.send({
            type: "WallpaperBack"
        })
        onApplied: root.send({
            type: "Close",
            monitor: root.screen.name
        })
    }

    CenterTheme {
        id: themeView
        visible: root.themeMode
        screen: root.screen
        x: Layout.earRadius + Layout.launcherPad
        y: Layout.launcherPad
        width: parent.width - 2 * (Layout.earRadius + Layout.launcherPad)
        focus: root.themeMode
        onVisibleChanged: if (visible)
            forceActiveFocus()
        onBack: root.send({
            type: "ThemeBack"
        })
        onApplied: root.send({
            type: "Close",
            monitor: root.screen.name
        })
    }

    CenterKeybinds {
        id: keybindsView
        visible: root.keybindsMode
        screen: root.screen
        x: Layout.earRadius + Layout.launcherPad
        y: Layout.launcherPad
        width: parent.width - 2 * (Layout.earRadius + Layout.launcherPad)
        onBack: root.send({
            type: "KeybindsBack"
        })
    }

    CenterWebapp {
        id: webappView
        visible: root.webappMode
        screen: root.screen
        x: Layout.earRadius + Layout.launcherPad
        y: Layout.launcherPad
        width: parent.width - 2 * (Layout.earRadius + Layout.launcherPad)
        focus: root.webappMode
        onVisibleChanged: if (visible)
            forceActiveFocus()
        onBack: root.send({
            type: "WebappBack"
        })
    }

    Column {
        id: column
        visible: !root.wallpaperMode && !root.themeMode && !root.keybindsMode && !root.webappMode

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Layout.earRadius + Layout.launcherPad
        anchors.rightMargin: Layout.earRadius + Layout.launcherPad
        anchors.topMargin: Layout.launcherPad
        spacing: Layout.launcherGap

        // Search glyph (by launcher mode) before the field.
        Row {
            width: parent.width
            spacing: Layout.launcherGap

            Text {
                id: glyph

                anchors.verticalCenter: parent.verticalCenter
                width: Layout.launcherIcon
                horizontalAlignment: Text.AlignHCenter
                text: (root.view.query ?? "").startsWith(">") ? Strings.launcherModeIcons.commands : Strings.launcherModeIcons.apps
                color: root.scheme.primary
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            TextInput {
                id: field

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - glyph.width - parent.spacing
                focus: root.visible
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
                // Each opening starts from an empty search.
                onVisibleChanged: if (visible) {
                    clear();
                    forceActiveFocus();
                }
                onTextChanged: root.send({
                    type: "LauncherQuery",
                    text: text
                })
                Keys.onPressed: event => {
                    event.accepted = true;
                    switch (event.key) {
                    case Qt.Key_Up:
                        return root.move(-1);
                    case Qt.Key_Down:
                        return root.move(1);
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        return root.launch(root.view.index ?? 0);
                    case Qt.Key_Escape:
                        return root.send({
                            type: "Close",
                            monitor: root.screen.name
                        });
                    }
                    event.accepted = false;
                }
            }
        }

        Rectangle {
            width: parent.width
            height: Layout.launcherDivider
            color: root.scheme.muted
            opacity: Colours.dividerAlpha
        }

        // Fixed per mode, so filtering does not resize the notch.
        Item {
            width: parent.width
            height: (root.commandMode ? Math.min(Layout.launcherRows, Strings.launcherCommands.length) : Layout.launcherRows) * Layout.launcherRowHeight

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.results.length === 0
                text: Strings.noMatches
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            ListView {
                id: list

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: root.commandMode ? parent.width * Layout.launcherCommandListRatio : parent.width
                clip: true
                model: root.results
                currentIndex: root.view.index ?? 0
                // Keeps the selection in sight while the arrows move it.
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool isSelected: index === list.currentIndex

                    width: list.width
                    height: Layout.launcherRowHeight

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Layout.launcherGap
                        transformOrigin: Item.Left
                        scale: row.isSelected ? Layout.launcherSelectedScale : 1

                        Behavior on scale {
                            Anim {}
                        }

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.commandMode
                            width: Layout.launcherIcon
                            height: Layout.launcherIcon
                            sourceSize.width: Layout.launcherIcon
                            sourceSize.height: Layout.launcherIcon
                            source: Quickshell.iconPath(row.modelData.icon ?? "", true)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.commandMode
                            width: Layout.launcherIcon
                            horizontalAlignment: Text.AlignHCenter
                            text: row.modelData.glyph ?? ""
                            color: row.isSelected ? root.scheme.primary : root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.launcherItem
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.name
                            color: row.isSelected ? root.scheme.primary : root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.launcherItem

                            Behavior on color {
                                ColorAnimation {
                                    duration: Timings.animNormal
                                }
                            }
                        }
                    }

                    // Passive, so it still sees the pointer under the notch's own
                    // hover zone; hovering selects like the arrows, a click launches.
                    HoverHandler {
                        onHoveredChanged: if (hovered)
                            root.send({
                                type: "LauncherSelect",
                                index: row.index
                            })
                    }

                    TapHandler {
                        onTapped: root.launch(row.index)
                    }
                }
            }

            Rectangle {
                id: commandDivider

                anchors.left: list.right
                anchors.leftMargin: Layout.launcherGap / 2
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Layout.launcherDivider
                visible: root.commandMode && root.results.length > 0
                color: root.scheme.muted
                opacity: Colours.dividerAlpha
            }

            Text {
                id: description

                anchors.left: commandDivider.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Layout.launcherGap
                visible: root.commandMode && root.results.length > 0
                text: root.results[root.view.index ?? 0]?.description ?? ""
                wrapMode: Text.WordWrap
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            Text {
                anchors.left: description.left
                anchors.right: description.right
                anchors.top: description.bottom
                anchors.topMargin: Layout.launcherGap
                visible: description.visible && root.results[root.view.index ?? 0]?.name !== Strings.wallpaperTitle && root.results[root.view.index ?? 0]?.name !== Strings.keybindsTitle && root.results[root.view.index ?? 0]?.name !== Strings.webappTitle
                text: Strings.launcherUnavailable
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }
        }
    }
}

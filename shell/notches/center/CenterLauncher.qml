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
    readonly property var results: LauncherSearch.rankApps(Apps.list, view.query ?? "")

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
        send({
            type: "LauncherActivate",
            appId: results[index]?.id ?? null
        });
    }

    NotchEarShape {
        anchors.fill: parent
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: Layout.earRadius + Layout.expandedPad
        anchors.rightMargin: Layout.earRadius + Layout.expandedPad
        anchors.topMargin: Layout.expandedPad
        spacing: Layout.launcherGap

        TextInput {
            id: field

            width: parent.width
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

        Text {
            visible: root.results.length === 0
            text: Strings.noMatches
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }

        ListView {
            id: list

            width: parent.width
            height: Layout.launcherRows * Layout.launcherRowHeight
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

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Layout.launcherIcon
                        height: Layout.launcherIcon
                        sourceSize.width: Layout.launcherIcon
                        sourceSize.height: Layout.launcherIcon
                        source: Quickshell.iconPath(row.modelData.icon ?? "", true)
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
    }
}

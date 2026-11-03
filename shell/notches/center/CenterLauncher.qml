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
            font.pixelSize: Fonts.title
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

        ListView {
            width: parent.width
            height: Layout.launcherRows * Layout.launcherRowHeight
            clip: true
            interactive: false
            model: root.results
            currentIndex: root.view.index ?? 0

            delegate: Row {
                id: row

                required property var modelData
                required property int index

                height: Layout.launcherRowHeight
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
                    color: row.index === (root.view.index ?? 0) ? root.scheme.primary : root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.body
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.genericName || row.modelData.comment || ""
                    color: root.scheme.muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.small
                }
            }
        }
    }
}

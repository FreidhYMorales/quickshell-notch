pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"

Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property var session: Wallpapers.selection
    readonly property int currentIndex: session?.index ?? -1

    signal back

    implicitHeight: Layout.wallpaperViewHeight

    function navigate(step) {
        Wallpapers.move(step, screen.name);
    }

    function confirm() {
        Wallpapers.commit(screen.name);
        back();
    }

    function cancel() {
        Wallpapers.cancel();
        back();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) {
            navigate(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            navigate(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            confirm();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            cancel();
            event.accepted = true;
        }
    }

    Column {
        anchors.fill: parent
        spacing: Layout.launcherGap

        Text {
            width: parent.width
            text: Strings.wallpaperTitle
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        Item {
            width: parent.width
            height: Layout.wallpaperCardHeight

            Text {
                anchors.centerIn: parent
                visible: Wallpapers.entries.length === 0
                text: Strings.wallpaperEmpty
                color: root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
            }

            ListView {
                id: carousel

                anchors.fill: parent
                visible: Wallpapers.entries.length > 0
                model: Wallpapers.entries
                orientation: ListView.Horizontal
                spacing: Layout.launcherGap
                clip: true
                currentIndex: root.currentIndex
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - Layout.wallpaperCardWidth / 2
                preferredHighlightEnd: width / 2 + Layout.wallpaperCardWidth / 2

                delegate: Item {
                    id: card

                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.currentIndex

                    width: Layout.wallpaperCardWidth
                    height: Layout.wallpaperCardHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: Layout.cardRadius
                        color: Colours.cardFor(root.screen)
                        border.width: card.selected ? Layout.launcherDivider : 0
                        border.color: root.scheme.primary
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: Layout.wallpaperCardPad
                            visible: !card.modelData.video
                            source: card.modelData.video ? "" : "file://" + card.modelData.path
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: card.modelData.video
                            text: Strings.wallpaperVideo
                            color: root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.launcherItem
                        }
                    }

                    TapHandler {
                        onTapped: Wallpapers.select(card.index, root.screen.name)
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: root.session?.entries[root.currentIndex]?.name ?? Strings.wallpaperEmpty
            color: root.scheme.onSurface
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }

        Text {
            width: parent.width
            text: Strings.wallpaperHint
            color: root.scheme.muted
            horizontalAlignment: Text.AlignHCenter
            font.family: Fonts.family
            font.pixelSize: Fonts.launcherItem
        }
    }
}

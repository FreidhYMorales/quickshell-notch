pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../../config"
import "../../services"

Item {
    id: root

    required property var screen
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property var session: Wallpapers.selection
    readonly property int currentIndex: session?.index ?? -1

    function wrappedIndex(offset) {
        const entries = root.session?.entries;
        const count = entries?.length ?? 0;
        const selected = root.currentIndex;
        if (count === 0 || selected < 0) return -1;
        return ((selected + offset) % count + count) % count;
    }

    signal back
    signal applied

    implicitHeight: Layout.wallpaperViewHeight

    function navigate(step) {
        Wallpapers.move(step, screen.name);
    }

    function confirm() {
        if (root.currentIndex < 0)
            return;
        Wallpapers.commit(screen.name);
        applied();
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

            // A fixed window of virtual slots makes the strip circular: the
            // first and last entries are always neighbors, even for short lists.
            Row {
                id: carousel
                anchors.centerIn: parent
                spacing: Layout.launcherGap
                visible: root.session?.entries.length > 0

                Repeater {
                    model: 3

                    delegate: Item {
                        id: card
                        required property int index
                        readonly property int offset: index - 1
                        readonly property int entryIndex: root.wrappedIndex(offset)
                        readonly property var entry: entryIndex >= 0
                            ? root.session.entries[entryIndex] : null
                        readonly property bool selected: offset === 0

                        width: Layout.wallpaperCardWidth
                        height: Layout.wallpaperCardHeight

                        Rectangle {
                            id: frame
                            anchors.fill: parent
                            radius: Layout.cardRadius
                            color: Colours.cardFor(root.screen)
                            border.width: card.selected ? Layout.launcherDivider : 0
                            border.color: root.scheme.primary

                            Image {
                                id: thumbnail
                                anchors.fill: parent
                                anchors.margins: Layout.wallpaperCardPad
                                visible: card.entry && !card.entry.video
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: maskShape
                                }
                                source: card.entry && !card.entry.video
                                    ? "file://" + card.entry.path : ""
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                            }

                            Rectangle {
                                id: maskShape
                                anchors.fill: thumbnail
                                radius: Math.max(0, Layout.cardRadius - Layout.wallpaperCardPad)
                                visible: false
                                layer.enabled: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: card.entry?.video ?? false
                                text: Strings.wallpaperVideo
                                color: root.scheme.onSurface
                                font.family: Fonts.family
                                font.pixelSize: Fonts.launcherItem
                            }
                        }

                        TapHandler {
                            onTapped: Wallpapers.select(card.entryIndex, root.screen.name)
                        }
                    }
                }
            }
        }

    }
}

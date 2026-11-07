import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

// Fullscreen picker with a bounded five-slot coverflow. Notch morph follows.
PanelWindow {
    id: root

    // Do not derive visibility from PanelWindow.screen: its assignment depends
    // on mapping, which creates a binding cycle when the window is hidden.
    required property string monitorName
    readonly property bool pickerOpen: CenterStore.quickWallpaper.phase === "open"
        && CenterStore.quickWallpaper.monitor === monitorName
    readonly property var session: Wallpapers.selection
    readonly property int currentIndex: session?.index ?? -1
    readonly property string previewPath: session?.preview ?? ""
    readonly property bool previewVideo: /\.(mp4|webm|mkv|mov|avi|m4v)$/i.test(previewPath)
    property date currentTime: new Date()
    readonly property var scheme: Colours.paletteFor(screen)

    function wrappedIndex(offset) {
        const entries = session?.entries;
        const count = entries?.length ?? 0;
        if (count === 0 || currentIndex < 0)
            return -1;
        return ((currentIndex + offset) % count + count) % count;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: pickerOpen
    color: Colours.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notch-quick-wallpaper"
    WlrLayershell.keyboardFocus: pickerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onPickerOpenChanged: {
        if (pickerOpen && previewVideo)
            videoPreview.play();
        else
            videoPreview.stop();
    }

    Timer {
        interval: 1000
        running: root.pickerOpen
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    Item {
        id: content
        anchors.fill: parent
        focus: root.pickerOpen
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                Wallpapers.move(-1, root.monitorName);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                Wallpapers.move(1, root.monitorName);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                CenterStore.applyQuickWallpaper();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                CenterStore.cancelQuickWallpaper();
                event.accepted = true;
            }
        }
        onVisibleChanged: if (visible) forceActiveFocus()

        Image {
            anchors.fill: parent
            visible: !root.previewVideo
            source: root.previewPath && !root.previewVideo
                ? "file://" + root.previewPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Error)
                    console.warn("QuickWallpaper: cannot load image " + root.previewPath);
            }
        }

        Video {
            id: videoPreview
            anchors.fill: parent
            visible: root.previewVideo
            source: root.previewVideo ? "file://" + root.previewPath : ""
            autoPlay: false
            onSourceChanged: {
                if (root.pickerOpen && root.previewVideo)
                    play();
            }
            onVisibleChanged: {
                if (visible && root.pickerOpen)
                    play();
                else
                    stop();
            }
            loops: MediaPlayer.Infinite
            muted: true
            fillMode: VideoOutput.PreserveAspectCrop
            onErrorOccurred: (error, errorString) => console.warn("QuickWallpaper: cannot play video " + root.previewPath + ": " + errorString)
        }

        Rectangle {
            anchors.fill: parent
            color: "#44000000"
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.16
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.currentTime, "hh:mm")
                color: "white"
                font.family: Fonts.family
                font.pixelSize: 64
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.currentTime, "dddd, d MMMM yyyy")
                color: "white"
                font.family: Fonts.family
                font.pixelSize: 22
            }
        }

        Item {
            id: coverflow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.max(20, parent.height * 0.045)
            width: Math.min(parent.width - 32, 840)
            height: Math.min(parent.height / 3, 250)

            readonly property real cardHeight: Math.min(height - 38, 208)
            readonly property real cardWidth: cardHeight * 0.68
            readonly property real step: Math.min(cardWidth * 1.18, width / 5.1)

            Repeater {
                model: 5

                delegate: Item {
                    id: card

                    required property int index
                    readonly property int offset: index - 2
                    readonly property int entryIndex: root.wrappedIndex(offset)
                    readonly property var entry: entryIndex < 0 ? null : root.session.entries[entryIndex]
                    readonly property bool selected: offset === 0

                    width: coverflow.cardWidth
                    height: coverflow.cardHeight
                    x: coverflow.width / 2 - width / 2 + offset * coverflow.step
                    y: selected ? 0 : Math.abs(offset) * 12 + 10
                    z: 3 - Math.abs(offset)
                    rotation: offset * -8
                    scale: selected ? 1 : (Math.abs(offset) === 1 ? 0.86 : 0.72)
                    opacity: entry ? (Math.abs(offset) === 2 ? 0.65 : 1) : 0

                    Behavior on x {
                        NumberAnimation { duration: Timings.animNormal; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        NumberAnimation { duration: Timings.animNormal; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: Timings.animNormal; easing.type: Easing.OutCubic }
                    }
                    Behavior on rotation {
                        NumberAnimation { duration: Timings.animNormal; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Layout.cardRadius
                        color: "#dd181818"
                        border.width: card.selected ? 3 : 1
                        border.color: card.selected ? root.scheme.primary : "#88ffffff"
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            visible: card.entry && !card.entry.video
                            source: card.entry && !card.entry.video ? "file://" + card.entry.path : ""
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: card.entry?.video ?? false

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "▶"
                                font.pixelSize: 32
                                color: "white"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "VIDEO"
                                font.family: Fonts.family
                                font.pixelSize: 12
                                color: "white"
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 32
                            color: "#99000000"

                            Text {
                                anchors.fill: parent
                                anchors.margins: 7
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                                text: card.entry?.name ?? ""
                                color: "white"
                                font.family: Fonts.family
                                font.pixelSize: 11
                            }
                        }
                    }

                    TapHandler {
                        enabled: card.entry !== null
                        onTapped: Wallpapers.select(card.entryIndex, root.monitorName)
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: root.currentIndex < 0 ? Strings.wallpaperEmpty
                    : (root.currentIndex + 1) + " / " + root.session.entries.length
                        + "   ·   ← → navegar   ·   Enter aplicar   ·   Esc cancelar"
                color: "white"
                font.family: Fonts.family
                font.pixelSize: 12
            }
        }
    }
}

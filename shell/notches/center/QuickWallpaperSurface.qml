import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

// First functional fullscreen increment. Coverflow and notch morph follow.
PanelWindow {
    id: root

    readonly property bool active: CenterStore.quickWallpaper.phase === "open"
        && CenterStore.quickWallpaper.monitor === screen.name
    readonly property var session: Wallpapers.selection
    readonly property int currentIndex: session?.index ?? -1
    readonly property string previewPath: session?.preview ?? ""
    readonly property var scheme: Colours.paletteFor(screen)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: active
    color: Colours.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notch-quick-wallpaper"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: content
        anchors.fill: parent
        focus: root.active
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                Wallpapers.move(-1, root.screen.name);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                Wallpapers.move(1, root.screen.name);
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
            source: root.previewPath && !/\\.(mp4|webm|mkv|mov|avi|m4v)$/i.test(root.previewPath)
                ? "file://" + root.previewPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
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
                text: Qt.formatTime(new Date(), "hh:mm")
                color: "white"
                font.family: Fonts.family
                font.pixelSize: 64
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                color: "white"
                font.family: Fonts.family
                font.pixelSize: 22
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            width: Math.min(parent.width - 48, 760)
            height: Math.min(parent.height / 3 - 24, 220)
            radius: Layout.cardRadius
            color: "#bb111111"

            Text {
                anchors.centerIn: parent
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                color: "white"
                font.family: Fonts.family
                font.pixelSize: Fonts.launcherItem
                text: root.currentIndex < 0 ? Strings.wallpaperEmpty
                    : (root.currentIndex + 1) + " / " + root.session.entries.length
                        + "   " + root.previewPath.split("/").pop()
            }
        }
    }
}

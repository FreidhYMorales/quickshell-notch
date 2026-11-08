import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../../logic/earGeometry.mjs" as EarGeometry
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
    readonly property bool secondaryPreview: Wallpapers.applyToAll && CenterStore.quickWallpaper.monitor !== monitorName
    readonly property string pickerPhase: CenterStore.quickWallpaper.monitor === monitorName || secondaryPreview
        ? CenterStore.quickWallpaper.phase : "closed"
    readonly property bool pickerOpen: pickerPhase === "open"
    readonly property bool pickerVisible: pickerPhase !== "closed"
    property real reveal: 0
    property bool waitingForFirstFrame: false

    function startReveal() {
        if (pickerPhase !== "opening" || !waitingForFirstFrame)
            return;
        waitingForFirstFrame = false;
        frameWait.stop();
        revealAnimation.to = 1;
        revealAnimation.restart();
    }
    onPickerPhaseChanged: {
        if (pickerPhase === "opening") {
            reveal = 0;
            waitingForFirstFrame = previewVideo;
            if (waitingForFirstFrame)
                frameWait.restart();
            else {
                revealAnimation.to = 1;
                revealAnimation.restart();
            }
        } else if (pickerPhase === "closing") {
            waitingForFirstFrame = false;
            frameWait.stop();
            revealAnimation.to = 0;
            revealAnimation.restart();
        } else if (pickerPhase === "closed") {
            waitingForFirstFrame = false;
            frameWait.stop();
            revealAnimation.stop();
            reveal = 0;
        }
    }
    readonly property var session: Wallpapers.selection
    readonly property int currentIndex: session?.index ?? -1
    readonly property string previewPath: session?.preview ?? (pickerVisible ? Wallpapers.pathFor(monitorName) : "")
    readonly property bool previewVideo: /\.(mp4|webm|mkv|mov|avi|m4v)$/i.test(previewPath)
    property date currentTime: new Date()
    readonly property var scheme: Colours.paletteFor(screen)

    function circularOffset(index) {
        const count = Wallpapers.entries.length;
        if (!count || currentIndex < 0)
            return 1000;
        let distance = ((index - currentIndex) % count + count) % count;
        if (distance > count / 2)
            distance -= count;
        return distance;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    visible: pickerVisible
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notch-quick-wallpaper"
    WlrLayershell.keyboardFocus: pickerOpen && !secondaryPreview ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    NumberAnimation {
        id: revealAnimation
        target: root
        property: "reveal"
        duration: Timings.animSlow
        easing.type: Easing.InOutCubic
        onFinished: {
            if (!root.secondaryPreview && root.pickerPhase === "opening")
                CenterStore.finishQuickWallpaperOpening();
            else if (!root.secondaryPreview && root.pickerPhase === "closing")
                CenterStore.finishQuickWallpaperClosing();
        }
    }

    Timer {
        id: frameWait
        interval: 1500
        repeat: false
        onTriggered: root.startReveal()
    }

    // Keep playback alive during the opening and closing reveal, not only
    // while the picker accepts keyboard input.
    onPickerVisibleChanged: {
        if (pickerVisible && previewVideo)
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

    // The widening panel pushes its ears outward; their concavity fades
    // smoothly as the preview reaches fullscreen (and returns on closing).
    readonly property real earMorph: {
        const t = Math.max(0, Math.min(1, (reveal - 0.45) / 0.55));
        return t * t * (3 - 2 * t);
    }
    readonly property real cornerMorph: {
        const t = Math.max(0, Math.min(1, (reveal - 0.20) / 0.80));
        return t * t * (3 - 2 * t);
    }

    // Match the idle notch first, then flatten to a fullscreen rectangle.
    Shape {
        id: revealMask
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: revealFrame.width
        height: revealFrame.height
        visible: false
        layer.enabled: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "white"
            strokeWidth: -1
            PathSvg {
                path: EarGeometry.notchPath(revealMask.width, revealMask.height,
                    Layout.earRadius * (1 - root.earMorph),
                    Layout.cornerRadius * (1 - root.cornerMorph))
            }
        }
    }

    Rectangle {
        id: revealFrame
        readonly property real notchWidth: Math.min(root.width,
            CenterStore.idleNotchWidths[root.monitorName] ?? Layout.cornerWidth)
        readonly property real notchHeight: Layout.idleHeight
        width: notchWidth + (root.width - notchWidth) * root.reveal
        height: notchHeight + (root.height - notchHeight) * root.reveal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        radius: 0
        color: Colours.background
        clip: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: revealMask
        }

    Item {
        id: content
        width: root.width
        height: root.height
        x: -revealFrame.x
        y: 0
        focus: root.pickerOpen && !root.secondaryPreview
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

        MediaPlayer {
            id: videoPreview
            source: root.previewVideo ? "file://" + root.previewPath : ""
            videoOutput: previewOutput
            loops: MediaPlayer.Infinite
            audioOutput: AudioOutput { muted: true }
            onSourceChanged: {
                if (root.pickerVisible && root.previewVideo)
                    play();
            }
            onErrorOccurred: (error, errorString) => console.warn("QuickWallpaper: cannot play video " + root.previewPath + ": " + errorString)
        }

        VideoOutput {
            id: previewOutput
            anchors.fill: parent
            visible: root.previewVideo
            fillMode: VideoOutput.PreserveAspectCrop
        }

        Connections {
            target: previewOutput.videoSink
            function onVideoFrameChanged(frame) {
                root.startReveal();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#44000000"
        }

        Column {
            visible: !root.secondaryPreview
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
            visible: !root.secondaryPreview

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.max(56, parent.height * 0.065)
            width: Math.min(parent.width - 32, 840)
            height: Math.min(parent.height / 3, 250)

            readonly property real cardHeight: Math.min(height - 38, 208)
            readonly property real cardWidth: cardHeight * 0.68
            readonly property real step: Math.min(cardWidth * 0.76, width / 6.5)

            Repeater {
                model: root.secondaryPreview ? [] : Wallpapers.entries

                delegate: Item {
                    id: card

                    required property int index
                    readonly property int offset: root.circularOffset(index)
                    readonly property int entryIndex: index
                    readonly property var entry: Wallpapers.entries[index]
                    readonly property bool nearby: Math.abs(offset) <= 2
                    readonly property bool inPreloadWindow: Wallpapers.isPreloaded(index)
                    readonly property bool selected: offset === 0
                    // Once visited, retain the source and decoded frame.
                    property bool thumbnailLoaded: false
                    onInPreloadWindowChanged: {
                        if (inPreloadWindow)
                            thumbnailLoaded = true;
                    }
                    Component.onCompleted: {
                        if (nearby)
                            thumbnailLoaded = true;
                    }
                    visible: nearby

                    width: coverflow.cardWidth
                    height: coverflow.cardHeight
                    x: coverflow.width / 2 - width / 2 + offset * coverflow.step
                    // Lower the outer cards so the fan follows one shared lower arc.
                    y: selected ? 0 : (Math.abs(offset) === 1 ? 20 : 66)
                    z: 3 - Math.abs(offset)
                    rotation: offset * 9
                    scale: selected ? 1 : (Math.abs(offset) === 1 ? 0.86 : 0.72)
                    opacity: nearby ? (Math.abs(offset) === 2 ? 0.65 : 1) : 0

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
                            source: card.thumbnailLoaded && card.entry && !card.entry.video ? "file://" + card.entry.path : ""
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: thumbnailMask
                            }
                        }

                        Rectangle {
                            id: thumbnailMask
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Math.max(0, Layout.cardRadius - 4)
                            visible: false
                            layer.enabled: true
                        }

                        // Hold a decoded video frame; only the fullscreen preview loops.
                        Video {
                            id: videoThumbnail
                            anchors.fill: parent
                            anchors.margins: 4
                            visible: card.entry?.video ?? false
                            source: card.thumbnailLoaded && card.entry?.video ? "file://" + card.entry.path : ""
                            autoPlay: false
                            muted: true
                            fillMode: VideoOutput.PreserveAspectCrop
                            onSourceChanged: {
                                if (card.thumbnailLoaded && source.toString() !== "")
                                    play();
                            }
                            onVisibleChanged: {
                                if (visible && source.toString() !== "")
                                    play();
                                else
                                    stop();
                            }
                            onPositionChanged: {
                                if (position >= 250 && playbackState === MediaPlayer.PlayingState)
                                    pause();
                            }
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: thumbnailMask
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: (card.entry?.video ?? false) && !videoThumbnail.hasVideo

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "▶"
                                font.pixelSize: 32
                                color: "white"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "CARGANDO"
                                font.family: Fonts.family
                                font.pixelSize: 12
                                color: "white"
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
                color: "white"
                font.family: Fonts.family
                font.pixelSize: 12
            }
        }
    }
    }
}
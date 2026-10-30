import QtQuick
import "../../components"
import "../../config"
import "../../services"
import "../../logic/centerLayout.mjs" as CenterLayout
import "../../logic/format.mjs" as Format
import "../../logic/sideLayer.mjs" as SideLayer

// Idle centre notch content: `(cpu) date . time (ram)` centred, so the clock
// never moves. The width is content-driven: `baseWidth` fits the row, and a
// side layer places its two items adjacent to the row; `sideNeed` is what the
// surface adds on EACH side (the wider item plus the row gap).
// Reading Battery and SysInfo here also starts those lazy singletons.
Item {
    id: root

    property var screen: null
    property var view: null
    // none, charging, plugged, full, low or media (CenterStore.sideLayer).
    property string batteryLayer: CenterStore.sideLayer
    readonly property int baseWidth: CenterLayout.idleBase({
        row: row.implicitWidth,
        pad: Layout.idlePad,
        ear: Layout.earRadius
    })
    readonly property int sideNeed: SideLayer.sideWidth(batteryLayer, {
        battery: CenterLayout.sideExtent({
            left: layerGlyph.implicitWidth,
            right: layerPercent.implicitWidth,
            gap: Layout.rowGap
        }),
        media: CenterLayout.sideExtent({
            left: art.implicitWidth,
            right: viz.implicitWidth,
            gap: Layout.rowGap
        })
    })
    readonly property bool mediaShown: batteryLayer === "media"
    // Outermost item of each side: the dots sit beyond it.
    readonly property Item leftEdge: mediaShown ? art : (layerShown ? layerGlyph : row)
    readonly property Item rightEdge: mediaShown ? viz : (layerShown ? layerPercent : row)

    readonly property var scheme: Colours.paletteFor(screen)
    readonly property bool layerShown: batteryLayer !== "none" && !mediaShown
    readonly property color layerColor: batteryLayer === "low" ? Colours.critical : scheme.primary

    function glyphFor(): string {
        switch (batteryLayer) {
        case "charging":
            return Strings.glyphBolt;
        case "plugged":
            return Strings.glyphPlug;
        case "full":
            return Strings.glyphBatteryFull;
        default:
            return Strings.glyphBatteryLow;
        }
    }

    NotchEarShape {
        anchors.fill: parent
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Layout.rowGap

        ArcMeter {
            anchors.verticalCenter: parent.verticalCenter
            value: SysInfo.cpu ?? 0
            icon: Strings.glyphCpu
            ringColor: root.scheme.primary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Format.shortDate(Time.month, Time.dayOfMonth, Strings.months) + Strings.dateTimeSeparator + Format.clock(Time.hours, Time.minutes)
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.idleClock
        }

        ArcMeter {
            anchors.verticalCenter: parent.verticalCenter
            value: SysInfo.ram ?? 0
            icon: Strings.glyphRam
            ringColor: root.scheme.primary
        }
    }

    // Recording dot, left of the row; it never changes the width.
    Rectangle {
        anchors.right: root.leftEdge.left
        anchors.rightMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        width: Layout.dotSize
        height: Layout.dotSize
        radius: Layout.dotSize / 2
        color: Colours.recording
        visible: Recorder.recording
    }

    // Unread dot, right of the row; it blinks only while a keyboard state mutes toasts.
    Rectangle {
        id: unread

        anchors.left: root.rightEdge.right
        anchors.leftMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        width: Layout.dotSize
        height: Layout.dotSize
        radius: Layout.dotSize / 2
        color: root.scheme.primary
        visible: CenterStore.unreadDot.visible

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: unread.visible && CenterStore.unreadDot.blinking
            // A blink cut mid-cycle must not leave the dot dimmed.
            onStopped: unread.opacity = 1

            NumberAnimation {
                to: 0.2
                duration: Timings.blink
            }
            NumberAnimation {
                to: 1
                duration: Timings.blink
            }
        }
    }

    ArtThumb {
        id: art

        anchors.right: row.left
        anchors.rightMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        visible: root.mediaShown
        source: Mpris.artUrl
        size: Layout.mediaArt
        glyphSize: Layout.mediaArtGlyph
        radius: Layout.mediaArtRadius
    }

    Visualizer {
        id: viz

        anchors.left: row.right
        anchors.leftMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        visible: root.mediaShown && Cava.available
        barColor: Mpris.artAccent
    }

    Text {
        id: layerGlyph

        anchors.right: row.left
        anchors.rightMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        visible: root.layerShown
        text: root.glyphFor()
        color: root.layerColor
        font.family: Fonts.family
        font.pixelSize: Fonts.idleSide
    }

    Text {
        id: layerPercent

        anchors.left: row.right
        anchors.leftMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        visible: root.layerShown
        text: Format.formatPercent(Battery.percentage)
        color: root.layerColor
        font.family: Fonts.family
        font.pixelSize: Fonts.idleSide
    }
}

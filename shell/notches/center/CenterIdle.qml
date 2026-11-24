import QtQuick
import "../../components"
import "../../config"
import "../../services"
import "../../logic/centerLayout.mjs" as CenterLayout
import "../../logic/format.mjs" as Format
import "../../logic/pixelShift.mjs" as PixelShift

// Idle centre notch content: `(cpu) date . time (ram)` centred, so the clock
// never moves. The width is content-driven: `baseWidth` fits the row, and a
// side layer places its two items adjacent to the row; `sideNeed` is what the
// surface adds on EACH side (the wider item plus the row gap).
// Reading Battery and SysInfo here also starts those lazy singletons.
Item {
    id: root

    property var screen: null
    property var view: null
    // OLED pixel shift: which spot of the one-pixel cycle the content is at.
    property int shiftStep: 0
    property real batteryPulseOpacity: 1
    readonly property var shiftOffset: PixelShift.shiftOffset(shiftStep)
    // none, charging, plugged, full, low or media (CenterStore.sideLayer).
    property string batteryLayer: CenterStore.sideLayer
    readonly property int baseWidth: CenterLayout.idleBase({
        row: row.implicitWidth,
        pad: Layout.idlePad,
        ear: Layout.earRadius
    })
    readonly property int sideNeed: mediaShown ? CenterLayout.sideExtent({
        left: art.implicitWidth,
        right: viz.implicitWidth,
        gap: Layout.rowGap
    }) : (layerShown ? CenterLayout.sideExtent({
            left: layerGlyph.implicitWidth,
            right: layerPercent.implicitWidth,
            gap: Layout.rowGap
        }) : 0)
    readonly property bool mediaShown: batteryLayer === "media" && Recorder.countdown === 0
    // Outermost item of each side: the dots sit beyond it.
    readonly property Item leftEdge: mediaShown ? art : (layerShown ? layerGlyph : row)
    readonly property Item rightEdge: mediaShown ? viz : (layerShown ? layerPercent : row)

    // What a visible dot or `!` adds on each side (CenterLayout.idleWidth).
    readonly property int dotExtent: critical.visible ? Layout.rowGap + critical.implicitWidth : (unread.visible ? Layout.rowGap + Layout.dotSize : 0)

    readonly property var scheme: Colours.paletteFor(screen)
    readonly property bool layerShown: Battery.present && Battery.infoVisible && !mediaShown && Recorder.countdown === 0
    readonly property bool atChargeLimit: Battery.plugged && Battery.chargeLimit > 0 && Battery.percentage >= Battery.chargeLimit
    readonly property color layerColor: Battery.chargeStage === "low" ? Colours.critical : (Battery.chargeStage === "medium" ? Colours.batteryMedium : Colours.batteryHigh)

    function glyphFor(): string {
        if (root.atChargeLimit || (Battery.plugged && !Battery.charging))
            return Strings.glyphPlug;
        if (Battery.charging)
            return Strings.glyphBolt;
        if (Battery.full)
            return Strings.glyphBatteryFull;
        return Strings.glyphBatteryLow;
    }

    // Moves every content item but the black shape, so the notch stays put.
    Translate {
        id: shift

        x: root.shiftOffset.x
        y: root.shiftOffset.y
    }

    Timer {
        interval: Timings.pixelShift
        running: true
        repeat: true
        onTriggered: root.shiftStep++
    }

    NotchEarShape {
        objectName: "idle-shape"
        anchors.fill: parent
        accentColor: Battery.present ? root.layerColor : root.scheme.primary
        accentOpacity: root.batteryPulseOpacity
    }

    SequentialAnimation on batteryPulseOpacity {
        loops: Animation.Infinite
        running: Battery.present && Battery.charging && !root.atChargeLimit
        onStopped: root.batteryPulseOpacity = 1

        NumberAnimation {
            from: 0.35
            to: 1
            duration: Timings.batteryPulse / 2
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            from: 1
            to: 0.35
            duration: Timings.batteryPulse / 2
            easing.type: Easing.InOutSine
        }
    }

    Row {
        id: row
        transform: shift

        objectName: "idle-row"
        anchors.centerIn: parent
        spacing: Layout.rowGap
        visible: Recorder.countdown === 0

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

    Text {
        transform: shift
        anchors.centerIn: parent
        visible: Recorder.countdown > 0
        text: Recorder.countdown
        color: root.scheme.onSurface
        font.family: Fonts.family
        font.pixelSize: Fonts.idleClock
    }

    // Recording dot, left of the row; it never changes the width.
    Rectangle {
        transform: shift
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
        transform: shift

        anchors.left: root.rightEdge.right
        anchors.leftMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        width: Layout.dotSize
        height: Layout.dotSize
        radius: Layout.dotSize / 2
        color: root.scheme.primary
        visible: CenterStore.unreadDot.visible && !critical.visible

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

    // Waiting criticals take the unread dot's place.
    CriticalMark {
        id: critical
        transform: shift

        anchors.left: root.rightEdge.right
        anchors.leftMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        visible: Notifs.pinned.length > 0
        onClicked: Notifs.reopen()
    }

    ArtThumb {
        id: art
        transform: shift

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
        transform: shift

        anchors.left: row.right
        anchors.leftMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        visible: root.mediaShown && Cava.available
        barColor: Mpris.artAccent
    }

    Text {
        id: layerGlyph
        transform: shift

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
        transform: shift

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

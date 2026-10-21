import QtQuick
import "../../components"
import "../../config"
import "../../services"
import "../../logic/format.mjs" as Format

// Idle centre notch content: `(cpu) date . time (ram)` centred, so the clock
// never moves. Battery layers use the fixed side slots (Layout.batterySide)
// just inside each ear; the surface grows the shape to make room for them.
// Reading Battery and SysInfo here also starts those lazy singletons.
Item {
    id: root

    property var screen: null
    property var view: null
    // none, charging, plugged, full or low (Battery.layer).
    property string batteryLayer: Battery.layer

    readonly property var scheme: Colours.paletteFor(screen)
    readonly property bool layerShown: batteryLayer !== "none"
    readonly property color layerColor: batteryLayer === "low" ? Colours.critical : scheme.primary

    function layerGlyph(): string {
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
            font.pixelSize: Fonts.body
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
        anchors.right: row.left
        anchors.rightMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        width: Layout.dotSize
        height: Layout.dotSize
        radius: Layout.dotSize / 2
        color: Colours.recording
        visible: Recorder.recording
    }

    // Unread dot, right of the row. The source is wired by a later change.
    Rectangle {
        id: unread

        anchors.left: row.right
        anchors.leftMargin: Layout.rowGap
        anchors.verticalCenter: parent.verticalCenter
        width: Layout.dotSize
        height: Layout.dotSize
        radius: Layout.dotSize / 2
        color: root.scheme.primary
        visible: !!root.view && root.view.blinkDot

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: unread.visible

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

    Item {
        anchors.left: parent.left
        anchors.leftMargin: Layout.earRadius
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Layout.batterySide
        visible: root.layerShown

        Text {
            anchors.centerIn: parent
            text: root.layerGlyph()
            color: root.layerColor
            font.family: Fonts.family
            font.pixelSize: Fonts.body
        }
    }

    Item {
        anchors.right: parent.right
        anchors.rightMargin: Layout.earRadius
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Layout.batterySide
        visible: root.layerShown

        Text {
            anchors.centerIn: parent
            text: Format.formatPercent(Battery.percentage)
            color: root.layerColor
            font.family: Fonts.family
            font.pixelSize: Fonts.small
        }
    }
}

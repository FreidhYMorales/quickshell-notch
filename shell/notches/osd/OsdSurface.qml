import QtQuick
import "../../components"
import "../../config"
import "../../logic/osd.mjs" as Osd
import "../../logic/reveal.mjs" as Reveal
import "../../logic/slider.mjs" as Maths
import "../../services"

// Volume (vr) or brightness (bl) OSD. Reveals when the service reports a real
// change, slides in from above, and stays open while hovered or dragged.
// Hidden while its service is unavailable or the slot is under osdMinWidth.
NotchSurface {
    id: root

    // "volume" or "brightness"
    property string kind: "volume"
    // Number on the outer (left) side; BL uses it, VR does not.
    property bool mirrored: false

    readonly property bool isVolume: kind === "volume"
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property bool ready: isVolume ? Audio.available : Brightness.available
    readonly property real range: isVolume ? 1 : 100
    // Raw level: volume may exceed 1, the label then shows the real percent.
    readonly property real level: isVolume ? Audio.rawVolume : Brightness.percent
    readonly property bool muted: isVolume && Audio.muted
    readonly property var sample: ({
            available: ready,
            source: isVolume ? Audio.sinkId : "backlight",
            value: level,
            muted: muted
        })
    readonly property var geo: ({
            track: 1,
            min: 0,
            max: range
        })
    readonly property var glyphs: isVolume ? Strings.volumeGlyphs : Strings.brightnessGlyphs
    property var previous: null
    property var reveal: Reveal.initialReveal()
    // Too narrow a slot never draws or takes input.
    readonly property bool open: slot.width >= Layout.osdMinWidth && Reveal.isVisible(reveal)

    function step(event) {
        const r = Reveal.stepReveal(reveal, event);
        reveal = r.state;
        if (r.timer === "restart")
            hide.restart();
        else if (r.timer === "stop")
            hide.stop();
    }

    function apply(value) {
        if (isVolume)
            Audio.setVolume(value);
        else
            Brightness.set(value);
    }

    shown: ready
    maskItem: maskBox
    onSampleChanged: {
        if (Osd.shouldReveal(previous, sample))
            step({
                type: "Trigger"
            });
        previous = sample;
    }
    Component.onCompleted: previous = sample

    Timer {
        id: hide

        interval: Timings.reveal
        onTriggered: root.step({
            type: "Timeout"
        })
    }

    Timer {
        interval: Timings.startupGate
        running: true
        onTriggered: root.step({
            type: "Ready"
        })
    }

    NotchEarShape {
        id: shape

        width: root.slot.width
        height: root.slot.height
        y: root.open ? 0 : -height

        Behavior on y {
            Anim {}
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            x: Layout.earRadius + Layout.osdPad
            width: parent.width - 2 * (Layout.earRadius + Layout.osdPad)
            from: 0
            to: root.range
            step: root.isVolume ? Limits.volumeStep : Limits.brightnessStep
            value: root.level
            muted: root.muted
            mirrored: root.mirrored
            scheme: root.scheme
            text: Maths.displayPercent(root.level, root.geo)
            icon: Maths.levelGlyph(root.level / root.range, root.muted, {
                high: Limits.levelHigh,
                mid: Limits.levelMid
            }, root.glyphs)
            onMoved: v => root.apply(v)
            onMuteToggled: {
                if (root.isVolume)
                    Audio.toggleMute();
            }
            onHeldChanged: root.step({
                type: "Hold",
                on: held
            })
        }
    }

    Item {
        id: maskBox

        width: shape.width
        height: root.open ? shape.height : 0
    }

    NotchZone {
        anchors.fill: maskBox
        onHoverChanged: on => root.step({
                type: "Hover",
                on: on
            })
    }
}

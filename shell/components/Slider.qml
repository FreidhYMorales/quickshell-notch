import QtQuick
import "../config"
import "../logic/slider.mjs" as Maths

// Horizontal slider with the icon inside a round thumb and the value beside
// the bar (`mirrored` puts the number on the left). The fill always grows
// left to right. Emits moved(value) for drag, tap and wheel; right-click
// emits muteToggled. The parent owns the value.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 0.05
    property string icon: ""
    property string text: ""
    property bool muted: false
    property bool mirrored: false
    property var scheme: null
    // True while a button is down, so the OSD does not time out mid-drag.
    readonly property bool held: area.pressed
    readonly property var geo: ({
            track: Math.max(0, bar.width - thumb.width),
            min: from,
            max: to
        })

    property real wheelCarry: 0

    signal moved(real value)
    signal muteToggled

    function dragTo(x) {
        root.moved(Maths.valueAt(x - bar.x - thumb.width / 2, geo));
    }

    implicitHeight: Layout.sliderHeight

    Text {
        id: number

        anchors.verticalCenter: parent.verticalCenter
        // Sized to its text; the bar takes the rest, so no empty space.
        x: root.mirrored ? 0 : root.width - width
        text: root.text
        color: root.scheme.onSurface
        font.family: Fonts.family
        font.pixelSize: Fonts.body
    }

    Item {
        id: bar

        x: root.mirrored ? number.width + Layout.gap : 0
        width: root.width - number.width - Layout.gap
        height: parent.height

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Layout.sliderHeight
            radius: height / 2
            color: root.scheme.muted
            opacity: Colours.trackAlpha
        }

        // Ends at the thumb's outer edge, so it is never narrower than the
        // thumb and keeps its round ends at 0. A darker primary than the thumb,
        // so the thumb stands out. Only the fill dims when muted.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: thumb.x + thumb.width
            height: Layout.sliderHeight
            radius: height / 2
            color: Qt.tint(Colours.background, Qt.alpha(root.scheme.primary, Colours.fillMix))
            opacity: root.muted ? Colours.mutedAlpha : 1
        }

        Rectangle {
            id: thumb

            x: Maths.positionOf(root.value, root.geo)
            anchors.verticalCenter: parent.verticalCenter
            width: Layout.sliderHeight
            height: width
            radius: width / 2
            color: root.scheme.primary

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: Colours.background
                font.family: Fonts.family
                font.pixelSize: Fonts.small
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: bar
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton)
                root.muteToggled();
            else
                root.dragTo(mouse.x + bar.x);
        }
        onPositionChanged: mouse => {
            if (pressed && mouse.buttons & Qt.LeftButton)
                root.dragTo(mouse.x + bar.x);
        }
        onWheel: wheel => {
            const r = Maths.accumulateWheel(root.wheelCarry, wheel.angleDelta.y);
            root.wheelCarry = r.carry;
            if (r.notches !== 0)
                root.moved(Maths.wheel(root.value, r.notches, {
                    step: root.step,
                    min: root.from,
                    max: root.to
                }));
        }
    }
}

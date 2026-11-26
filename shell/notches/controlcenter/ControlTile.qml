import QtQuick
import "../../components"
import "../../config"

// One round toggle button, icon only: solid primary when on, a translucent
// primary when off. Left click toggles, right click opens the tile's detail.
Rectangle {
    id: root

    property var scheme
    property bool on: false
    property string glyph: ""

    signal toggled
    signal detailRequested

    width: Layout.ccTile
    height: Layout.ccTile
    radius: Layout.ccTile / 2
    scale: pointer.hovered || input.activeFocus ? Layout.powerSelectedScale : 1
    color: {
        const p = Qt.color(scheme.primary);
        return on ? p : Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
    }

    Behavior on color {
        ColorAnimation {
            duration: Timings.animFast
        }
    }

    Behavior on scale {
        Anim {}
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.on ? Colours.background : root.scheme.onSurface
        font.family: Fonts.family
        font.pixelSize: Fonts.control
    }

    // The cursor lives on a HoverHandler: a MouseArea with cursorShape takes
    // the hover and the control center would collapse.
    HoverHandler {
        id: pointer

        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        id: input

        objectName: "cc-control-tile-" + root.glyph
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                event.accepted = true;
                if (!event.isAutoRepeat)
                    root.toggled();
            } else if (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier) {
                event.accepted = true;
                if (!event.isAutoRepeat)
                    root.detailRequested();
            }
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.detailRequested();
            else
                root.toggled();
        }
    }
}

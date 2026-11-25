import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Media column: art, track text and previous / play-pause / next.
FocusScope {
    id: root

    objectName: "center-media"
    property var scheme: Colours.fallback
    property bool keyboardMode: false
    property var player: Mpris
    focus: keyboardMode

    function focusFirst() {
        if (previous.enabled)
            previous.forceActiveFocus();
        else
            playPause.forceActiveFocus();
    }

    // One transport glyph; dimmed and inert when `enabled` is false.
    component Control: Text {
        id: control

        signal clicked
        property color idleColor: root.scheme.onSurface
        readonly property bool highlighted: hover.hovered || activeFocus

        activeFocusOnTab: enabled
        opacity: enabled ? 1 : Colours.dimAlpha
        color: highlighted ? root.scheme.primary : idleColor
        scale: highlighted ? Layout.powerSelectedScale : 1
        font.family: Fonts.family
        font.pixelSize: Fonts.control

        Behavior on color {
            ColorAnimation {
                duration: Timings.animNormal
            }
        }

        Behavior on scale {
            Anim {}
        }

        HoverHandler {
            id: hover
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Layout.controlGap / 2
            enabled: control.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: control.clicked()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                event.accepted = true;
                if (!event.isAutoRepeat)
                    control.clicked();
            } else {
                event.accepted = false;
            }
        }
    }

    implicitHeight: Layout.artSize

    ArtThumb {
        id: art

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        source: root.player.artUrl
        glyphColor: root.scheme.muted
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: Layout.expandedGap
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Layout.rowGap / 2

        Text {
            width: parent.width
            text: root.player.title
            elide: Text.ElideRight
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.title
        }

        Text {
            width: parent.width
            text: root.player.album
            elide: Text.ElideRight
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.small
        }

        Text {
            width: parent.width
            text: root.player.artist
            elide: Text.ElideRight
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.small
        }

        Row {
            spacing: Layout.controlGap

            Control {
                id: previous

                objectName: "media-prev"
                text: Strings.glyphPrev
                enabled: root.player.canPrev
                onClicked: root.player.previous()
            }

            Control {
                id: playPause

                objectName: "media-play-pause"
                text: root.player.playing ? Strings.glyphPause : Strings.glyphPlay
                idleColor: root.scheme.primary
                onClicked: root.player.togglePlay()
            }

            Control {
                id: next

                objectName: "media-next"
                text: Strings.glyphNext
                enabled: root.player.canNext
                onClicked: root.player.next()
            }
        }
    }
}

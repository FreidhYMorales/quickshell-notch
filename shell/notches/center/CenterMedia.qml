import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Media column: art, track text and previous / play-pause / next.
Item {
    id: root

    property var scheme: Colours.fallback

    // One transport glyph; dimmed and inert when `enabled` is false.
    component Control: Text {
        id: control

        signal clicked

        opacity: enabled ? 1 : Colours.dimAlpha
        font.family: Fonts.family
        font.pixelSize: Fonts.control

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Layout.controlGap / 2
            enabled: control.enabled
            onClicked: control.clicked()
        }
    }

    implicitHeight: Layout.artSize

    ArtThumb {
        id: art

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        source: Mpris.artUrl
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
            text: Mpris.title
            elide: Text.ElideRight
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.title
        }

        Text {
            width: parent.width
            text: Mpris.album
            elide: Text.ElideRight
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.small
        }

        Text {
            width: parent.width
            text: Mpris.artist
            elide: Text.ElideRight
            color: root.scheme.muted
            font.family: Fonts.family
            font.pixelSize: Fonts.small
        }

        Row {
            spacing: Layout.controlGap

            Control {
                text: Strings.glyphPrev
                color: root.scheme.onSurface
                enabled: Mpris.canPrev
                onClicked: Mpris.previous()
            }

            Control {
                text: Mpris.playing ? Strings.glyphPause : Strings.glyphPlay
                color: root.scheme.primary
                onClicked: Mpris.togglePlay()
            }

            Control {
                text: Strings.glyphNext
                color: root.scheme.onSurface
                enabled: Mpris.canNext
                onClicked: Mpris.next()
            }
        }
    }
}

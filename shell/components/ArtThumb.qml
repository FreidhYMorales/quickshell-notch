import QtQuick
import Quickshell.Widgets
import "../config"

// Rounded album art. A music glyph stands in when there is no source or the
// image has not loaded. Shared by the expanded media column and the idle
// media layer.
ClippingRectangle {
    id: root

    property url source: ""
    property real size: Layout.artSize
    property real glyphSize: Layout.artGlyph
    property color glyphColor: Colours.fallback.muted
    property color fillColor: Colours.background

    readonly property bool hasArt: source.toString() !== "" && image.status === Image.Ready

    implicitWidth: size
    implicitHeight: size
    radius: Layout.artRadius
    color: fillColor

    Image {
        id: image

        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: root.hasArt
    }

    Text {
        anchors.centerIn: parent
        visible: !root.hasArt
        text: Strings.glyphMusic
        color: root.glyphColor
        font.family: Fonts.family
        font.pixelSize: root.glyphSize
    }
}

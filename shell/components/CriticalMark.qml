import QtQuick
import "../config"

// The `!` for critical notifications waiting to be dismissed. It only emits
// `clicked`; the owner decides what reopens.
Text {
    id: root

    signal clicked

    text: Strings.criticalMark
    color: Colours.critical
    font.family: Fonts.family
    font.pixelSize: Fonts.idleSide
    font.bold: true

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Layout.rowGap / 2
        onClicked: root.clicked()
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import "../config"
import "../logic/notifToast.mjs" as NotifToast

// A notification's icon in a fixed square box: its image, else its app icon,
// else the bell glyph. Theme icons take the accent like the bell; pictures
// (screenshots, avatars) keep their colours.
Item {
    id: root

    property var notif: null
    property var scheme
    property int size: Layout.toastIcon
    property int glyphSize: Fonts.toast

    readonly property var info: notif ? NotifToast.toastIconInfo({
        image: notif.image,
        appIcon: notif.appIcon
    }, name => Quickshell.iconPath(name, true)) : {
        source: "",
        themed: false
    }

    width: size
    height: size

    Image {
        id: icon

        anchors.fill: parent
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        source: root.info.source
        visible: root.info.source !== "" && status !== Image.Error
        layer.enabled: root.info.themed
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.scheme.primary
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !icon.visible
        text: Strings.glyphBell
        color: root.scheme.primary
        font.family: Fonts.family
        font.pixelSize: root.glyphSize
    }
}

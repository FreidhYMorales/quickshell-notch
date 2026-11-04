import QtQuick
import Quickshell

ShellRoot {
    id: root

    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var sleep: Services.SleepLock }', root)

    Component.onCompleted: console.log("sleep lock smoke: inhibit " + root.services.sleep.inhibit)

    Timer {
        interval: 1500
        running: true
        onTriggered: Qt.exit(0)
    }
}

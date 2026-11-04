import QtQuick
import Quickshell

ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var caffeine: Services.Caffeine }', root)
    Component.onCompleted: console.log("caffeine: " + root.services.caffeine.enabled)
    Connections {
        target: root.services.caffeine
        function onEnabledChanged() {
            console.log("caffeine: " + root.services.caffeine.enabled);
        }
    }
    Timer {
        interval: 8000
        running: true
        onTriggered: Qt.exit(0)
    }
}

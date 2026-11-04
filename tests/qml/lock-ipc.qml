import QtQuick
import Quickshell

ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var session: Services.Session }', root)
    Connections {
        target: root.services.session
        function onLockRequested() {
            console.log("lock: requested");
        }
    }
    Timer {
        interval: 5000
        running: true
        onTriggered: Qt.exit(0)
    }
}

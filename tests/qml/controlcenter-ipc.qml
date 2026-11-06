import QtQuick
import Quickshell

// Drives shell/services/Requests.qml directly so the IPC targets can be hit
// with `qs -p ... ipc call` without starting the whole notch.
ShellRoot {
    id: root

    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var requests: Services.Requests }', root)

    Connections {
        target: root.services.requests

        function onControlCenter(view, monitor) {
            console.log("controlcenter: " + view + " " + monitor);
        }
    }

    Timer {
        interval: 8000
        running: true

        onTriggered: Qt.exit(0)
    }
}

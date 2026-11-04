import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var idle: Services.Idle }', root)
    TestCase {
        name: "IdleImport"
        when: true
        function test_import() {
            const idle = root.services.idle;
            for (let i = 0; i < 50 && !idle.saved; i++)
                wait(100);
            const t = idle.timeouts;
            console.log("idle timeouts: " + t.screensaver + "/" + t.lock + "/" + t.suspend);
            Qt.exit(0);
        }
    }
}

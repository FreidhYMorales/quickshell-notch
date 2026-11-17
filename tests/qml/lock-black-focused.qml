import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root
    property bool woke: false

    FloatingWindow {
        id: window
        implicitWidth: 800
        implicitHeight: 600
        visible: true

        Item {
            id: host
            anchors.fill: parent
        }
    }

    TestCase {
        name: "LockBlackFocused"
        when: window.visible

        function test_focused_password_wakes_black() {
            const url = Quickshell.env("NOTCH_LOCK_URL");
            const auth = Qt.createQmlObject('import QtQuick; QtObject { property string user: "tester"; property bool fingerprintEnabled: false; property string error: ""; property string fingerprintState: "idle"; function submit(text) {} }', root);
            const component = Qt.createComponent(url + "/LockContent.qml");
            const content = component.createObject(host, {
                auth: auth,
                "anchors.fill": host
            });
            content.woke.connect(() => root.woke = true);
            content.wake();
            wait(700);
            content.stage = "black";
            wait(100);
            keyClick(Qt.Key_A);
            wait(100);
            if (!root.woke) {
                console.error("lock black: focused password consumed wake key");
                return Qt.exit(2);
            }
            console.log("lock black: focused password wakes on first key");
            Qt.exit(0);
        }
    }
}

import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root

    property bool unlocked: false

    function find(items, test) {
        for (const item of items) {
            if (item.visible && test(item))
                return item;
            const children = item.children;
            const found = children && typeof children.length === "number" ? find(children, test) : null;
            if (found)
                return found;
        }
        return null;
    }

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
        name: "LockContentWrong"
        when: window.visible

        function test_wrong_then_right() {
            const url = Quickshell.env("NOTCH_LOCK_URL");
            const auth = Qt.createQmlObject('import "' + url + '"; LockPam { configDirectory: "' + Quickshell.env("NOTCH_LOCK_PAM_DIR") + '"; passwordConfig: "password"; fingerprintConfig: "fingerprint"; fingerprintEnabled: false }', root);
            auth.unlocked.connect(() => root.unlocked = true);
            const component = Qt.createComponent(url + "/LockContent.qml");
            if (component.status !== Component.Ready) {
                console.error(component.errorString());
                return Qt.exit(2);
            }
            component.createObject(host, {
                auth: auth,
                "anchors.fill": host
            });
            wait(500);
            const input = root.find(host.children, item => item.activeFocus && item.cursorPosition !== undefined);
            if (!input)
                return Qt.exit(2);
            input.insert(0, Quickshell.env("NOTCH_LOCK_WRONG"));
            keyClick(Qt.Key_Return);
            tryVerify(() => auth.error !== "", 5000);
            wait(100);
            const shown = root.find(host.children, item => item.text === "Login failed" && item.cursorPosition === undefined);
            if (shown && input.text === "" && !root.unlocked)
                console.log("lock content: shown " + shown.text + ", field empty");
            input.insert(0, Quickshell.env("NOTCH_LOCK_TRY"));
            keyClick(Qt.Key_Return);
            tryVerify(() => root.unlocked, 5000);
            console.log("lock content: unlocked");
            Qt.exit(0);
        }
    }
}

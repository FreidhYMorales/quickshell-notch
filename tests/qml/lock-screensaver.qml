import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root

    property bool woke: false

    function find(items, wanted) {
        for (const item of items) {
            if (item.visible && wanted(item))
                return item;
            const children = item.children;
            const found = children && typeof children.length === "number" ? find(children, wanted) : null;
            if (found)
                return found;
        }
        return null;
    }

    function named(name) {
        return root.find(host.children, item => item.objectName === name);
    }

    function stubAuth() {
        return Qt.createQmlObject('import QtQuick; QtObject { property string user: "tester"; property bool fingerprintEnabled: false; property string error: ""; property string fingerprintState: "idle"; function submit(text) {} }', root);
    }

    function makeContent(stage) {
        const url = Quickshell.env("NOTCH_LOCK_URL");
        const component = Qt.createComponent(url + "/LockContent.qml");
        if (component.status !== Component.Ready) {
            console.error(component.errorString());
            return null;
        }
        const content = component.createObject(host, {
            auth: root.stubAuth(),
            stage: stage,
            "anchors.fill": host
        });
        if (!content) {
            console.error("lock screensaver: cannot create the content");
            return null;
        }
        content.woke.connect(() => root.woke = true);
        return content;
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
        name: "LockScreensaver"
        when: window.visible

        function test_screensaver_and_black() {
            let content = root.makeContent("screensaver");
            if (!content)
                return Qt.exit(2);
            wait(300);
            content.forceActiveFocus();
            if (root.named("lock-clock"))
                return Qt.exit(3);
            if (root.named("lock-form"))
                return Qt.exit(4);
            if (root.named("lock-hint"))
                return Qt.exit(5);
            keyClick(Qt.Key_Space);
            wait(100);
            if (!root.woke)
                return Qt.exit(6);
            // The surface ends the stage and opens the form.
            content.stage = "normal";
            content.wake();
            wait(700);
            if (!root.named("lock-clock"))
                return Qt.exit(7);
            if (!root.named("lock-form"))
                return Qt.exit(8);
            content.destroy();
            wait(100);

            root.woke = false;
            content = root.makeContent("black");
            if (!content)
                return Qt.exit(9);
            wait(300);
            content.forceActiveFocus();
            if (root.named("lock-clock"))
                return Qt.exit(10);
            if (root.named("lock-hint"))
                return Qt.exit(11);
            keyClick(Qt.Key_Space);
            wait(100);
            if (!root.woke)
                return Qt.exit(12);
            if (root.named("lock-form"))
                return Qt.exit(13);
            console.log("lock screensaver: hidden, woke, form shown");
            Qt.exit(0);
        }
    }
}

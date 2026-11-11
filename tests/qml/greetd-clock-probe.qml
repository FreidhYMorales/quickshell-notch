import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    property real previousClockY: -1
    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        surface = component.createObject(null, {
            demo: false
        });
        if (!surface || surface.view !== "clock") {
            Qt.exit(2);
            return;
        }
        surface.showLogin();
        if (surface.view !== "login") {
            Qt.exit(3);
            return;
        }
        if (typeof surface.loginProgress !== "number" || surface.loginProgress >= 1) {
            Qt.exit(5);
            return;
        }
        if (typeof surface.clockPosition !== "number") {
            Qt.exit(10);
            return;
        }
        checkTransition.start();
        sample.start();
    }
    Timer {
        id: sample
        interval: 40
        repeat: true
        onTriggered: {
            const current = root.surface.clockPosition;
            if (root.previousClockY >= 0 && current > root.previousClockY + 0.1) {
                Qt.exit(9);
                return;
            }
            root.previousClockY = current;
        }
    }
    Timer {
        id: checkTransition
        interval: 650
        onTriggered: {
            if (root.surface.loginProgress < 0.99) {
                Qt.exit(6);
                return;
            }
            if (Math.abs(root.surface.clockPosition - root.surface.height * 0.25) > 0.5) {
                Qt.exit(11);
                return;
            }
            sample.stop();
            root.surface.showClock();
            if (root.surface.view !== "clock") {
                Qt.exit(4);
                return;
            }
            if (!root.surface.loginControls || !root.surface.loginControls.visible || root.surface.loginControls.enabled) {
                Qt.exit(7);
                return;
            }
            checkClosed.start();
        }
    }
    Timer {
        id: checkClosed
        interval: 650
        onTriggered: {
            if (root.surface.loginProgress > 0.01 || root.surface.loginControls.visible) {
                Qt.exit(8);
                return;
            }
            Qt.exit(42);
        }
    }
}

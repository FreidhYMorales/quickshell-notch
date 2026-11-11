import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        surface = component.createObject(null, {
            demo: true,
            parityPreview: true
        });
        if (!surface || surface.view !== "clock" || !surface.demo || !surface.parityPreview) {
            Qt.exit(2);
            return;
        }
        surface.showLogin();
        if (surface.view !== "login" || !surface.accountAvatar || surface.users.length < 1) {
            Qt.exit(3);
            return;
        }
        if (surface.passwordField.enabled || surface.footerPowerEnabled) {
            Qt.exit(5);
            return;
        }
        if (!surface.passwordField.visible || surface.simulationButtonsVisible || !surface.simulationArrowVisible) {
            Qt.exit(7);
            return;
        }
        if (surface.passwordField.text !== "") {
            Qt.exit(8);
            return;
        }
        surface.simulatedDelayMs = 50;
        surface.submitDemo(false);
        if (surface.stateName !== "authenticating" || !surface.compressionRunning) {
            Qt.exit(4);
            return;
        }
        finished.start();
    }
    Timer {
        id: finished
        interval: 900
        onTriggered: {
            if (root.surface.stateName !== "launched" || root.surface.reveal > 0.01) {
                Qt.exit(6);
                return;
            }
            Qt.exit(42);
        }
    }
}

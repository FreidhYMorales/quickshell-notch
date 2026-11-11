import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    QtObject {
        id: backend
        property string lastAction: ""
        function power(action) {
            lastAction = action;
        }
    }
    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        surface = component.createObject(null, {
            demo: false,
            protocolBackend: backend
        });
        if (!surface) {
            Qt.exit(2);
            return;
        }
        surface.showLogin();
        surface.sessionSelector.popup.open();
        popupCheck.start();
    }
    Timer {
        id: popupCheck
        interval: 300
        onTriggered: {
            const popup = root.surface.sessionSelector.popup;
            const list = popup.contentItem;
            const option = list.itemAtIndex(0);
            if (!popup.visible || !option || option.width > list.width || option.background.radius < 8 || popup.background.radius < option.background.radius || popup.padding < 5) {
                Qt.exit(13);
                return;
            }
            popup.close();
            root.checkInitial();
        }
    }
    function checkInitial() {
        if (surface.loginControls.width !== 284 || surface.loginControls.height !== 40 || surface.passwordField.parent !== surface.loginControls || surface.sessionSelector.width !== 190 || surface.sessionSelector.height !== 34 || surface.sessionSelector.count !== 1) {
            Qt.exit(8);
            return;
        }
        if (!surface.submitIcon || !surface.sessionIcon || surface.submitIcon.width !== 20 || surface.submitIcon.height !== 20 || surface.sessionIcon.width !== 16 || surface.sessionIcon.height !== 16 || surface.submitIcon.status !== Image.Ready || surface.sessionIcon.status !== Image.Ready) {
            iconCheck.start();
            return;
        }
        finishChecks();
    }
    function finishChecks() {
        if (surface.virtualKeyboardPanel.visible) {
            Qt.exit(9);
            return;
        }
        surface.requestPower("bad-action");
        if (backend.lastAction !== "") {
            Qt.exit(3);
            return;
        }
        surface.requestPower("reboot");
        if (backend.lastAction !== "reboot") {
            Qt.exit(4);
            return;
        }
        backend.lastAction = "";
        surface.stateName = "authenticating";
        surface.requestPower("poweroff");
        if (backend.lastAction !== "") {
            Qt.exit(5);
            return;
        }
        surface.stateName = "form";
        surface.demo = true;
        surface.parityPreview = true;
        surface.toggleKeyboard();
        if (!surface.keyboardRequested || !surface.virtualKeyboardPanel.visible || surface.passwordField.enabled) {
            Qt.exit(10);
            return;
        }
        surface.toggleKeyboard();
        if (surface.virtualKeyboardPanel.visible) {
            Qt.exit(11);
            return;
        }
        surface.requestPower("poweroff");
        if (backend.lastAction !== "") {
            Qt.exit(6);
            return;
        }
        surface.showClock();
        if (surface.view !== "clock") {
            Qt.exit(7);
            return;
        }
        Qt.exit(42);
    }
    Timer {
        id: iconCheck
        interval: 300
        onTriggered: {
            if (!root.surface.submitIcon || !root.surface.sessionIcon || root.surface.submitIcon.width !== 20 || root.surface.submitIcon.height !== 20 || root.surface.sessionIcon.width !== 16 || root.surface.sessionIcon.height !== 16 || root.surface.submitIcon.status !== Image.Ready || root.surface.sessionIcon.status !== Image.Ready) {
                Qt.exit(12);
                return;
            }
            root.finishChecks();
        }
    }
}

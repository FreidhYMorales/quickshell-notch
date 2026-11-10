import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
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
        surface.showClock();
        if (surface.view !== "clock") {
            Qt.exit(4);
            return;
        }
        Qt.exit(42);
    }
}

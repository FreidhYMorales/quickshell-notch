import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    QtObject {
        id: backend
        function begin(user, password) {
        }
    }
    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        surface = component.createObject(null, {
            demo: false,
            protocolBackend: backend,
            authTimeoutMs: 5000
        });
        surface.submit("preview-user", "dummy-secret");
        prompt.start();
    }
    Timer {
        id: prompt
        interval: 800
        onTriggered: {
            if (root.surface.reveal > 0.01) {
                Qt.exit(3);
                return;
            }
            root.surface.protocolMessage = "Additional verification";
            root.surface.promptSecret = true;
            root.surface.awaitingPrompt = true;
            expanded.start();
        }
    }
    Timer {
        id: expanded
        interval: 800
        onTriggered: {
            if (root.surface.reveal < 0.99 || root.surface.stateName !== "authenticating" || root.surface.statusText() !== "Additional verification") {
                Qt.exit(4);
                return;
            }
            Qt.exit(42);
        }
    }
}

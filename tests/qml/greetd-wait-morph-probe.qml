import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    property int launched: 0
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
        if (!surface) {
            Qt.exit(2);
            return;
        }
        surface.protocolAnimationComplete.connect(() => root.launched++);
        surface.submit("preview-user", "dummy-secret");
        checkWaiting.start();
    }
    Timer {
        id: checkWaiting
        interval: 800
        onTriggered: {
            if (root.surface.stateName !== "authenticating" || root.surface.reveal > 0.01 || root.launched !== 0) {
                Qt.exit(3);
                return;
            }
            root.surface.completeAuthentication(false);
            checkLaunch.start();
        }
    }
    Timer {
        id: checkLaunch
        interval: 200
        onTriggered: {
            if (root.launched !== 1 || root.surface.stateName !== "launched") {
                Qt.exit(4);
                return;
            }
            Qt.exit(42);
        }
    }
}

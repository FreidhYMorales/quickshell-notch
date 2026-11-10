import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    property int step: 0
    QtObject {
        id: backend
        property int attempts: 0
        function begin(user, password) {
            attempts++;
        }
    }
    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        surface = component.createObject(null, {
            demo: false,
            protocolBackend: backend,
            authTimeoutMs: 50
        });
        if (!surface) {
            Qt.exit(2);
            return;
        }
        surface.submit("test-user", "dummy-secret");
        probe.start();
    }
    Timer {
        id: probe
        interval: 800
        onTriggered: {
            if (!root.surface.authTimedOut || root.surface.stateName !== "authenticating" || root.surface.reveal !== 1 || root.surface.statusText().indexOf("pending") < 0) {
                Qt.exit(3);
                return;
            }
            root.surface.submit("test-user", "dummy-secret");
            if (backend.attempts !== 1) {
                Qt.exit(4);
                return;
            }
            root.surface.completeAuthentication(false);
            if (root.surface.authTimedOut || root.surface.stateName !== "animating") {
                Qt.exit(5);
                return;
            }
            root.surface.destroy();
            const component = Qt.createComponent("../../greetd/preview/Main.qml");
            root.surface = component.createObject(null, {
                demo: false,
                protocolBackend: backend,
                authTimeoutMs: 50
            });
            root.surface.submit("test-user", "dummy-secret");
            lateFailure.start();
        }
    }
    Timer {
        id: lateFailure
        interval: 800
        onTriggered: {
            if (!root.surface.authTimedOut) {
                Qt.exit(6);
                return;
            }
            root.surface.completeAuthentication(true);
            if (root.surface.authTimedOut || root.surface.stateName !== "rejecting") {
                Qt.exit(7);
                return;
            }
            Qt.exit(42);
        }
    }
}

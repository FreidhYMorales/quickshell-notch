import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    property int samples: 0
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
            foreground: "#ffffff",
            accent: "#0000ff",
            authTimeoutMs: 5000
        });
        if (!surface) {
            Qt.exit(2);
            return;
        }
        surface.submit("preview-user", "dummy-secret");
        peak.start();
    }
    Timer {
        id: peak
        interval: 35
        repeat: true
        onTriggered: {
            root.samples++;
            if (root.samples > 70) {
                Qt.exit(3);
                return;
            }
            if (root.surface.lockGlyph && root.surface.lockGlyph.scale > 1.10 && root.surface.lockGlyph.color.r < 0.2) {
                stop();
                root.samples = 0;
                valley.start();
            }
        }
    }
    Timer {
        id: valley
        interval: 35
        repeat: true
        onTriggered: {
            root.samples++;
            if (root.samples > 50) {
                Qt.exit(4);
                return;
            }
            if (root.surface.lockGlyph.scale < 1.02 && root.surface.lockGlyph.color.r > 0.8) {
                stop();
                root.surface.completeAuthentication(true);
                failed.start();
            }
        }
    }
    Timer {
        id: failed
        interval: 80
        onTriggered: {
            if (!Qt.colorEqual(root.surface.lockGlyph.color, "#ff7777")) {
                Qt.exit(5);
                return;
            }
            Qt.exit(42);
        }
    }
}

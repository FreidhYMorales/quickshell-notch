import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    property var preview
    property int step: 0
    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        if (component.status !== Component.Ready) {
            Qt.exit(2);
            return;
        }
        preview = component.createObject(null);
        if (!preview) {
            Qt.exit(3);
            return;
        }
        probe.start();
    }
    Timer {
        id: probe
        interval: 850
        repeat: true
        onTriggered: {
            if (root.step === 0) {
                root.preview.submitDemo(false);
                if (root.preview.stateName !== "authenticating" || root.preview.reveal !== 1) {
                    Qt.exit(4);
                    return;
                }
            } else if (root.step === 1) {
                if (root.preview.stateName !== "animating") {
                    Qt.exit(5);
                    return;
                }
            } else if (root.step === 2) {
                if (root.preview.stateName !== "launched") {
                    Qt.exit(6);
                    return;
                }
            } else if (root.step === 4) {
                if (root.preview.stateName !== "form") {
                    Qt.exit(7);
                    return;
                }
                root.preview.submitDemo(true);
            } else if (root.step === 5) {
                if (root.preview.stateName !== "rejecting") {
                    Qt.exit(9);
                    return;
                }
            } else if (root.step === 7) {
                if (root.preview.stateName !== "error" || root.preview.reveal !== 1) {
                    Qt.exit(8);
                    return;
                }
                Qt.exit(42);
            }
            root.step++;
        }
    }
}

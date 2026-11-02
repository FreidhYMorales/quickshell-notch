import QtQuick
import Quickshell

ShellRoot {
    Timer {
        interval: 10
        running: true
        onTriggered: {
            if (Quickshell.env("NOTCH_QML_TEST_FAIL") === "1") {
                console.error("notch-qml-test: expected failure");
                Qt.exit(7);
            } else {
                console.log("notch-qml-test: success");
                Qt.exit(0);
            }
        }
    }
}

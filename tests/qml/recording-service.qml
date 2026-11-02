import QtQuick
import Quickshell

ShellRoot {
    id: root
    property var recorder: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var service: Services.Recorder }', root).service
    property int step: 0
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (step === 0) {
                if (typeof root.recorder.setRecording !== "function") {
                    console.error("recording service: invalid test setup");
                    return Qt.exit(2);
                }
                if (typeof root.recorder.start === "function") root.recorder.start();
            } else if (step === 1 && !root.recorder.recording) {
                console.error("recording service: did not start");
                return Qt.exit(1);
            } else if (step === 1) {
                if (typeof root.recorder.stop === "function") root.recorder.stop();
            } else if (root.recorder.recording) {
                console.error("recording service: did not stop");
                return Qt.exit(1);
            } else {
                console.log("recording service: started and stopped");
                return Qt.exit(0);
            }
            step++;
        }
    }
}

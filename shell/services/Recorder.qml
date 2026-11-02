pragma Singleton

import Quickshell
import Quickshell.Io
import "../config"

// Minimal recording state for the idle notch's red dot. The capture process
// port arrives with the control centre's Rec tile (notch-control-center).
Singleton {
    id: root

    readonly property bool recording: privateRecording
    property bool privateRecording: false

    function setRecording(value: bool) {
        privateRecording = value;
    }

    function start() {
        if (privateRecording || mkdir.running || reserve.running || recorder.running)
            return;
        const dir = Quickshell.env("QS_RECORDINGS_DIR") || Quickshell.env("HOME") + "/Videos/Recordings";
        reserve.command = ["mktemp", "--suffix=.mp4", dir + "/recording-XXXXXXXX"];
        mkdir.command = ["mkdir", "-p", dir];
        mkdir.running = true;
    }

    function stop() {
        if (recorder.running)
            recorder.signal(2);
    }

    Process {
        id: mkdir

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                reserve.running = true;
        }
    }

    Process {
        id: reserve

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (!path)
                    return;
                recorder.command = ["gpu-screen-recorder", "-w", "screen", "-a", "default_output", "-c", "mp4", "-o", path];
                recorder.didStart = false;
                recorder.running = true;
                root.privateRecording = true;
            }
        }
    }

    Process {
        id: recorder

        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && !didStart && root.privateRecording) {
                root.privateRecording = false;
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.privateRecording = false;
            if (exitCode !== 0)
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
        }
    }
}

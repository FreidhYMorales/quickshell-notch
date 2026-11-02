pragma Singleton

import Quickshell
import Quickshell.Io

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
        if (privateRecording || reserve.running || recorder.running)
            return;
        const dir = Quickshell.env("QS_RECORDINGS_DIR") || Quickshell.env("HOME") + "/Videos/Recordings";
        reserve.command = ["mktemp", "--suffix=.mp4", dir + "/recording-XXXXXXXX"];
        reserve.running = true;
    }

    function stop() {
        if (recorder.running)
            recorder.signal(2);
    }

    Process {
        id: reserve

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (!path)
                    return;
                recorder.command = ["gpu-screen-recorder", "-w", "screen", "-a", "default_output", "-c", "mp4", "-o", path];
                recorder.running = true;
                root.privateRecording = true;
            }
        }
    }

    Process {
        id: recorder

        onExited: root.privateRecording = false
    }
}

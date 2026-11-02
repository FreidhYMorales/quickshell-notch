pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"

// Minimal recording state for the idle notch's red dot. The capture process
// port arrives with the control centre's Rec tile (notch-control-center).
Singleton {
    id: root

    readonly property bool recording: privateRecording
    property bool privateRecording: false
    property int countdown: 0
    property string outputPath: ""

    signal sidecarClaimed(bool success)

    function claimSidecar(source: string, target: string) {
        if (sidecarClaim.running)
            return;
        sidecarClaim.command = ["ln", "--", source, target];
        sidecarClaim.running = true;
    }

    Process {
        id: sidecarClaim

        onExited: (exitCode, exitStatus) => root.sidecarClaimed(exitCode === 0)
    }

    function setRecording(value: bool) {
        privateRecording = value;
    }

    function beginCountdown() {
        if (countdown > 0 || privateRecording || mkdir.running || reserve.running || recorder.running)
            return;
        countdown = Limits.recordingCountdown;
        countdownTimer.start();
    }

    function cancelCountdown() {
        countdownTimer.stop();
        countdown = 0;
    }

    Timer {
        id: countdownTimer

        interval: Timings.recordingCountdownTick
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown === 0) {
                stop();
                root.start();
            }
        }
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
        if (recorder.running) {
            recorder.stopRequested = true;
            recorder.signal(2);
        }
    }

    Process {
        id: mkdir

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                reserve.running = true;
            else
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
        }
    }

    Process {
        id: reserve

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (!path)
                    return;
                root.outputPath = path;
                recorder.command = ["gpu-screen-recorder", "-w", "screen", "-a", "default_output", "-c", "mp4", "-o", path];
                recorder.didStart = false;
                recorder.stopRequested = false;
                recorder.running = true;
                root.privateRecording = true;
            }
        }
    }

    Process {
        id: recorder

        property bool didStart: false
        property bool stopRequested: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && !didStart && root.privateRecording) {
                root.privateRecording = false;
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.privateRecording = false;
            if (exitCode !== 0 || !stopRequested)
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
            else
                Notifs.postNormal(Strings.center, Strings.recordingSaved, root.outputPath, "");
        }
    }
}

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
    property bool preparing: false
    property bool preparingCapture: false
    property bool pendingStop: false
    property int reservationAttempts: 0
    property int publicationAttempts: 0
    property string recordingsDir: ""
    property string workspacePath: ""
    property string capturePath: ""
    property string publicationStem: ""

    signal sidecarClaimed(bool success)
    signal workspaceCreated(string path)

    onWorkspaceCreated: path => {
        if (!preparing)
            return;
        if (!path) {
            reservationFailed();
            return;
        }
        workspacePath = path;
        reserve.command = ["mktemp", "--suffix=.mp4", path + "/recording-XXXXXXXX"];
        reserveCandidate();
    }

    function createWorkspace(parent: string) {
        if (workspace.running)
            return;
        workspace.streamDone = false;
        workspace.exitDone = false;
        workspace.didStart = false;
        workspace.pending = true;
        workspace.path = "";
        workspace.command = ["mktemp", "-d", "--", parent + "/.notch-recording-XXXXXXXX"];
        workspace.running = true;
    }

    Process {
        id: workspace

        property bool streamDone: false
        property bool exitDone: false
        property bool didStart: false
        property bool pending: false
        property int exitCode: -1
        property string path: ""

        function finish() {
            if (pending && streamDone && exitDone) {
                pending = false;
                root.workspaceCreated(exitCode === 0 ? path : "");
            }
        }

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                root.workspaceCreated("");
            }
        }
        onExited: (code, exitStatus) => {
            exitCode = code;
            exitDone = true;
            finish();
        }

        stdout: StdioCollector {
            onStreamFinished: {
                workspace.path = text.trim();
                workspace.streamDone = true;
                workspace.finish();
            }
        }
    }

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
        if (countdown > 0 || privateRecording || preparing || recorder.running)
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
        if (privateRecording || preparing || recorder.running)
            return;
        preparing = true;
        preparingCapture = true;
        pendingStop = false;
        reservationAttempts = 0;
        mkdir.didStart = false;
        recordingsDir = Quickshell.env("QS_RECORDINGS_DIR") || Quickshell.env("HOME") + "/Videos/Recordings";
        mkdir.command = ["mkdir", "-p", recordingsDir];
        runHelper(mkdir);
    }

    // Runs one helper under the watchdog; a late exit after a timeout is
    // ignored because the helper is no longer the active one.
    property var activeHelper: null
    property var timedOutHelper: null

    function runHelper(helper: var) {
        activeHelper = helper;
        helperTimer.restart();
        helper.running = true;
    }

    // Called when a helper ends. True only for the active helper; a helper
    // that already timed out reports its timeout once and returns false.
    function claimHelper(helper: var): bool {
        if (timedOutHelper === helper) {
            timedOutHelper = null;
            helperTimedOut(helper);
            return false;
        }
        if (activeHelper !== helper)
            return false;
        activeHelper = null;
        helperTimer.stop();
        return true;
    }

    Timer {
        id: helperTimer

        interval: Timings.recordingHelperTimeout
        onTriggered: {
            const helper = root.activeHelper;
            root.activeHelper = null;
            root.timedOutHelper = helper;
            // Children go first: a shell helper's commands would be orphaned.
            // The outcome is reported only once the helper is gone.
            if (helper && helper.running && helper.processId) {
                reaper.helper = helper;
                reaper.command = ["pkill", "-KILL", "-P", String(helper.processId)];
                reaper.running = true;
            } else {
                root.claimHelper(helper);
            }
        }
    }

    function helperTimedOut(helper: var) {
        if (helper === publish)
            publicationFailed();
        else if (helper === cleanup)
            cleanupFinished(false);
        else
            reservationFailed();
    }

    function reserveCandidate() {
        reservationAttempts++;
        reserve.running = true;
    }

    function reservationFailed() {
        preparing = false;
        preparingCapture = false;
        pendingStop = false;
        Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
    }

    function stop() {
        if (preparingCapture)
            pendingStop = true;
        if (recorder.running) {
            recorder.stopRequested = true;
            if (recorder.ready)
                recorder.signal(2);
        }
    }

    FileView {
        id: readiness

        path: root.privateRecording ? root.capturePath + ".ts" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (text().trim() && recorder.running && !recorder.ready) {
                recorder.ready = true;
                readyTimer.stop();
                if (recorder.stopRequested)
                    recorder.signal(2);
            }
        }
    }

    Timer {
        id: readyTimer

        interval: Timings.recordingReadyTimeout
        onTriggered: {
            if (recorder.running && !recorder.ready)
                recorder.signal(9);
        }
    }

    Process {
        id: mkdir

        property bool didStart: false
        onStarted: didStart = true
        onRunningChanged: {
            if (!running && !didStart && root.claimHelper(mkdir))
                root.reservationFailed();
        }
        onExited: (exitCode, exitStatus) => {
            if (!root.claimHelper(mkdir))
                return;
            if (exitCode === 0)
                root.createWorkspace(root.recordingsDir);
            else
                root.reservationFailed();
        }
    }

    Process {
        id: reserve

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.reservationFailed();
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (!path)
                    return;
                root.outputPath = path;
                root.capturePath = path;
                reserveSidecar.command = ["sh", "-c", "set -C; : > \"$1\" && ln -- \"$1\" \"$2\"", "sh", path + ".ts", path + ".owner"];
                reserveSidecar.running = true;
            }
        }
    }

    function publishCandidate() {
        publicationAttempts++;
        outputPath = recordingsDir + "/" + publicationStem + "-" + publicationAttempts + ".mp4";
        publish.command = ["ln", "--", capturePath, outputPath];
        runHelper(publish);
    }

    function publicationFailed() {
        preparing = false;
        outputPath = capturePath;
        Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingRecoveryBody.arg(capturePath), "");
    }

    Process {
        id: publish

        property bool didStart: false
        onStarted: didStart = true
        onRunningChanged: {
            if (!running && !didStart && root.claimHelper(publish))
                root.publicationFailed();
        }
        onExited: (exitCode, exitStatus) => {
            if (!root.claimHelper(publish))
                return;
            if (exitCode === 0) {
                cleanup.command = ["sh", "-c", "if [ \"$1\" -ef \"$2\" ] && [ \"$3\" -ef \"$4\" ]; then rm -- \"$1\" \"$2\" \"$3\" && rmdir -- \"$5\"; else exit 1; fi", "sh", root.capturePath + ".ts", root.capturePath + ".owner", root.capturePath, root.outputPath, root.workspacePath];
                root.runHelper(cleanup);
            } else if (root.publicationAttempts < Limits.recordingReservationAttempts) {
                Qt.callLater(root.publishCandidate);
            } else {
                root.publicationFailed();
            }
        }
    }

    Process {
        id: cleanup

        onExited: (exitCode, exitStatus) => {
            if (root.claimHelper(cleanup))
                root.cleanupFinished(exitCode === 0);
        }
    }

    Process {
        id: reaper

        property var helper: null

        onRunningChanged: {
            if (!running && helper) {
                const stalled = helper;
                helper = null;
                if (stalled.running)
                    stalled.signal(9);
                else
                    root.claimHelper(stalled);
            }
        }
    }

    function cleanupFinished(success: bool) {
        if (!success)
            console.warn("Recording workspace cleanup incomplete: " + workspacePath);
        preparing = false;
        Notifs.postNormal(Strings.center, Strings.recordingSaved, outputPath, "");
    }

    Process {
        id: reserveSidecar

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (root.reservationAttempts < Limits.recordingReservationAttempts)
                    Qt.callLater(root.reserveCandidate);
                else
                    root.reservationFailed();
                return;
            }
            recorder.command = ["gpu-screen-recorder", "-w", "screen", "-a", "default_output", "-c", "mp4", "-o", root.outputPath, "-write-first-frame-ts", "yes"];
            recorder.didStart = false;
            recorder.stopRequested = root.pendingStop;
            root.pendingStop = false;
            root.preparingCapture = false;
            recorder.ready = false;
            recorder.running = true;
            root.privateRecording = true;
            root.preparing = false;
            readyTimer.start();
        }
    }

    Process {
        id: recorder

        property bool didStart: false
        property bool stopRequested: false
        property bool ready: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && !didStart && root.privateRecording) {
                readyTimer.stop();
                root.privateRecording = false;
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingFailedBody, "");
            }
        }
        onExited: (exitCode, exitStatus) => {
            readyTimer.stop();
            root.privateRecording = false;
            if (exitCode !== 0 || !stopRequested || !ready)
                Notifs.post(Strings.center, Strings.recordingFailed, Strings.recordingPartialBody.arg(root.capturePath), "");
            else {
                root.preparing = true;
                root.publicationAttempts = 0;
                root.publicationStem = "recording-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + "-" + root.workspacePath.split("/").pop();
                publish.didStart = false;
                root.publishCandidate();
            }
        }
    }
}

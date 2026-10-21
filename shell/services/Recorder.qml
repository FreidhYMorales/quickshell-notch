pragma Singleton

import Quickshell

// Minimal recording state for the idle notch's red dot. The capture process
// port arrives with the control centre's Rec tile (notch-control-center).
Singleton {
    id: root

    readonly property bool recording: privateRecording
    property bool privateRecording: false

    function setRecording(value: bool) {
        privateRecording = value;
    }
}

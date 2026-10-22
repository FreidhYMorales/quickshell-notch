pragma Singleton

import Quickshell
import QtQml
import Quickshell.Services.Pipewire
import "../config"
import "../logic/slider.mjs" as Slider

// Default sink volume and mute, reactive on Pipewire. No processes: reads and
// writes go through the bound node, so keybinds and other apps show up here.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink && sink.ready ? sink.audio : null

    readonly property bool available: audio !== null
    // Identifies the sink so the OSD can tell a sink switch from a change.
    readonly property int sinkId: sink ? sink.id : -1
    // What the node holds; may exceed 1 (over-amplified), the OSD shows it.
    readonly property real rawVolume: audio ? audio.volume : 0
    // 0..1 for the slider.
    readonly property real volume: Slider.clamp(rawVolume, 0, 1)
    readonly property bool muted: audio ? audio.muted : false

    function setVolume(v: real) {
        if (!audio || Flags.smoke || !isFinite(v))
            return;
        audio.volume = Slider.clamp(v, 0, 1);
    }

    function toggleMute() {
        if (!audio || Flags.smoke)
            return;
        audio.muted = !audio.muted;
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}

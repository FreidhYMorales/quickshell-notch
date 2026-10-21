pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../logic/palette.mjs" as PaletteLogic

Singleton {
    id: root

    // Notches are pure black; cards are black mixed with a little of the accent.
    readonly property color background: "#000000"
    readonly property real cardMix: 0.08

    // Low and critical battery.
    readonly property color critical: "#ff5449"
    // Red dot shown while screen recording is active.
    readonly property color recording: "#ff3b30"
    // Opacity of the unfilled part of an arc meter.
    readonly property real trackAlpha: 0.2
    // Opacity of secondary text and of disabled controls.
    readonly property real dimAlpha: 0.6

    // Used until (or unless) matugen output is available.
    readonly property var fallback: ({
            primary: "#adc6ff",
            onSurface: "#e2e2e9",
            muted: "#c4c6d0"
        })

    // Palette parsed from matugen's dark scheme, shared by every monitor.
    property var global: fallback
    // Per-monitor palettes keyed by screen name; filled in once wallpapers exist.
    property var overrides: ({})

    readonly property string palettePath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/matugen/colors.json"

    // paletteFor(screen) -> { primary, onSurface, muted }
    function paletteFor(screen): var {
        return overrides[screen?.name] ?? global;
    }

    // cardFor(screen) -> colour of an inner card on that screen
    function cardFor(screen): color {
        const p = Qt.color(paletteFor(screen).primary);
        return Qt.tint(background, Qt.rgba(p.r, p.g, p.b, cardMix));
    }

    FileView {
        path: root.palettePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.global = PaletteLogic.parsePalette(text()) ?? root.fallback
        onLoadFailed: root.global = root.fallback
    }
}

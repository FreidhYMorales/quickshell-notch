pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../logic/palette.mjs" as PaletteLogic
import "../logic/themeState.mjs" as ThemeState
import "../services"

Singleton {
    id: root

    // Notches are pure black; cards are black mixed with a little of the accent.
    readonly property color background: Theme.current.mode === "light" ? "#f8f8fc" : "#000000"
    readonly property real cardMix: 0.08
    // Control center toggle button fill while off (primary at this alpha).
    readonly property real tileOffAlpha: 0.18
    // Divider lines inside control center cards (muted at this opacity).
    readonly property real dividerAlpha: 0.3

    // Low and critical battery.
    readonly property color critical: "#ff5449"
    // Red dot shown while screen recording is active.
    readonly property color recording: "#ff3b30"
    // Opacity of the unfilled part of an arc meter.
    readonly property real trackAlpha: 0.2
    // Opacity of secondary text and of disabled controls.
    readonly property real dimAlpha: 0.6
    // Opacity of a muted slider fill: higher than dimAlpha so it still reads
    // on the black notch.
    readonly property real mutedAlpha: 0.8
    // Share of primary mixed into the black notch for a slider fill, so the
    // full-primary thumb stands out against it.
    readonly property real fillMix: 0.55

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
        return ThemeState.themePalette(Theme.current, overrides[screen?.name] ?? global);
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

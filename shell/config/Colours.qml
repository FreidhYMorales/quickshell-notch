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
    // Control center toggle button fill while off (primary at this alpha).
    readonly property real tileOffAlpha: 0.18
    // A tile-off tint laid over another one, like a notification row inside
    // its card: the lighter accent fill for controls straight on the notch.
    readonly property real raisedAlpha: 1 - (1 - tileOffAlpha) * (1 - tileOffAlpha)
    // Divider lines inside control center cards (muted at this opacity).
    readonly property real dividerAlpha: 0.3
    // Fine accent on the exposed lower edge of black notch shapes.
    readonly property real notchEdgeAlpha: 0.45
    readonly property real notchEdgeWidth: 2

    // Low and critical battery.
    readonly property color critical: "#ff5449"
    readonly property color batteryMedium: "#ffbf47"
    readonly property color batteryHigh: "#4caf50"
    // Security fingerprint hover feedback: remove (red) and add (green).
    readonly property color securityRemoveHover: "#ff5449"
    readonly property color securityAddHover: "#4caf50"
    // Red dot shown while screen recording is active.
    readonly property color recording: "#ff3b30"
    // Opacity of the unfilled part of an arc meter.
    readonly property real trackAlpha: 0.2
    // Opacity of secondary text and of disabled controls.
    readonly property real dimAlpha: 0.6
    // Opacity of calendar days outside the shown month.
    readonly property real outsideAlpha: 0.35
    // Opacity of a muted slider fill: higher than dimAlpha so it still reads
    // on the black notch.
    readonly property real mutedAlpha: 0.8
    // Share of primary mixed into the black notch for a slider fill, so the
    // full-primary thumb stands out against it.
    readonly property real fillMix: 0.55

    // Used until (or unless) matugen output is available. Neutral greys keep
    // the notch readable when matugen is missing: a colourless theme is better
    // than the wrong colours.
    readonly property var fallback: ({
            primary: "#c6c6c6",
            onSurface: "#e4e4e4",
            muted: "#b0b0b0"
        })

    // Palette parsed from the apps' colors.json: dark unless the apps are light.
    property var appPalette: fallback
    // Dark dry-run palette the theme service sets while the apps are light.
    property var shared: null
    // The notch's dark palette shared by every monitor.
    readonly property var global: shared ?? appPalette
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
        onLoaded: root.appPalette = PaletteLogic.parsePalette(text()) ?? root.fallback
        onLoadFailed: root.appPalette = root.fallback
    }
}

pragma Singleton

import Quickshell

// Every user-visible text lives here.
Singleton {
    readonly property string workspaces: "Workspaces"
    readonly property string brightness: "Brightness"
    readonly property string volume: "Volume"
    readonly property string controlCenter: "Control center"
    readonly property string center: "Notch"

    // Calendar names (index 0 = January, 0 = Monday).
    readonly property var months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // Player text fallbacks.
    readonly property string unknownTitle: "Unknown title"
    readonly property string unknownAlbum: "Unknown album"
    readonly property string unknownArtist: "Unknown artist"

    readonly property string dateTimeSeparator: " \u00b7 "

    // Nerd Font glyphs for the idle row and battery layers.
    readonly property string glyphCpu: "\uf2db"
    readonly property string glyphRam: "\uf538"
    readonly property string glyphBatteryFull: "\uf240"
    readonly property string glyphBatteryLow: "\uf243"
    readonly property string glyphBolt: "\uf0e7"
    readonly property string glyphPlug: "\uf1e6"

    // Media glyphs: placeholder art and transport controls.
    readonly property string glyphMusic: "\udb81\udf5a"
    readonly property string glyphPrev: "\uf048"
    readonly property string glyphNext: "\uf051"
    readonly property string glyphPlay: "\uf04b"
    readonly property string glyphPause: "\uf04c"
}

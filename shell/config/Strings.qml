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

    // Nerd Font glyphs for the battery layers.
    readonly property string glyphBolt: "\uf0e7"
    readonly property string glyphPlug: "\uf1e6"
}

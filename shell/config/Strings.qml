pragma Singleton

import Quickshell

// Every user-visible text lives here.
Singleton {
    readonly property string workspaces: "Workspaces"
    readonly property string brightness: "Brightness"
    readonly property string volume: "Volume"
    readonly property string controlCenter: "Control center"
    readonly property string center: "Notch"
    // Control center profile: "up 3h 12m".
    readonly property string uptimePrefix: "up "
    // Control center notifications section; %1 = how many.
    readonly property string notificationsTitle: "Notifications (%1)"
    readonly property string noNotifications: "No notifications"
    // Launcher line when the query matches no app.
    readonly property string noMatches: "No matches"
    readonly property string launcherUnavailable: "Not available yet"
    readonly property var launcherCommands: [
        {
            name: "Wallpaper",
            glyph: "󰸉",
            description: "Choose the desktop wallpaper. Notch colours follow it."
        },
        {
            name: "Theme",
            glyph: "󰏘",
            description: "Choose the theme."
        },
        {
            name: "Keybinds",
            glyph: "󰌌",
            description: "View keyboard shortcuts."
        }
    ]
    // Launcher glyph before the field, keyed by mode: magnify for apps,
    // pound for commands.
    readonly property var launcherModeIcons: ({
            apps: "\udb80\udf49",
            commands: "#"
        })
    // Notifications subpage: the link that opens it and its chevrons.
    readonly property string seeAll: "See all"
    readonly property string glyphChevronRight: "\uf054"
    readonly property string glyphChevronLeft: "\uf053"
    // Control center toggle tiles.
    readonly property string glyphWifi: "\udb81\udda9"
    readonly property string glyphBluetooth: "\udb80\udcaf"
    readonly property string glyphDnd: "\udb80\udc9b"
    readonly property string glyphRecording: "󰻃"
    readonly property string glyphStop: "\uf04d"
    readonly property string recordingFailed: "Recording failed"
    readonly property string recordingFailedBody: "Screen recording stopped unexpectedly."
    readonly property string recordingRecoveryBody: "Could not save the recording. Recover it from: %1"
    readonly property string recordingPartialBody: "Recording stopped. A partial file may be available at: %1"
    readonly property string recordingSaved: "Recording saved"
    readonly property string recordingLeftover: "Interrupted recordings found"
    readonly property string recordingLeftoverBody: "%1 interrupted recording(s) can be recovered from hidden folders in: %2"

    // Calendar names (index 0 = January, 0 = Monday).
    readonly property var months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // Player text fallbacks.
    readonly property string unknownTitle: "Unknown title"
    readonly property string unknownAlbum: "Unknown album"
    readonly property string unknownArtist: "Unknown artist"

    readonly property string dateTimeSeparator: " \u00b7 "

    // Notification toast: "App: summary", the queued count ("+2") and close.
    readonly property string toastAppSeparator: ": "
    readonly property string toastWaitingPrefix: "+"
    readonly property string glyphClose: "\uf00d"
    // Polkit fingerprint prompt icon (nf-md-fingerprint).
    readonly property string glyphFingerprint: "\udb80\ude37"
    readonly property string glyphBell: "\uf0f3"
    // Shell-made critical toast at the battery critical limit; %1 = percentage.
    readonly property string batteryCriticalApp: "Battery"
    readonly property string batteryCriticalSummary: "Battery critical"
    readonly property string batteryCriticalBody: "%1% left. Plug in the charger."
    readonly property string batteryCriticalIcon: "battery-caution"
    // Power menu icons, keyed by action.
    readonly property var powerIcons: ({
            lock: "󰌾",
            suspend: "󰤄",
            logout: "󰍃",
            reboot: "󰜉",
            poweroff: "⏻"
        })
    // Critical notifications waiting to be dismissed (click reopens the newest).
    readonly property string criticalMark: "!"

    // Nerd Font glyphs for the idle row and battery layers.
    readonly property string glyphCpu: "\uf2db"
    readonly property string glyphRam: "\uf538"
    readonly property string glyphBatteryFull: "\uf240"
    readonly property string glyphBatteryLow: "\uf243"
    readonly property string glyphBolt: "\uf0e7"
    readonly property string glyphPlug: "\uf1e6"

    // Workspaces notch: Arch logo, slot symbols and special workspace glyphs.
    readonly property string glyphArch: "\uf303"
    readonly property string symbolActive: "\u25cf"
    readonly property string symbolEmpty: "\u2013"
    readonly property string unknownInitial: "?"
    readonly property string glyphSpecial: "\uf005"
    // Tray item menu: a checked option shows this mark.
    readonly property string glyphCheck: "\uf00c"
    readonly property string glyphChevronDown: "\uf078"
    readonly property var specialGlyphs: ({
            messaging: "\uf075",
            music: glyphMusic,
            magic: "\uf0d0",
            terminal: "\uf120"
        })

    // OSD icons (shown inside the slider thumb).
    readonly property var volumeGlyphs: ({
            muted: "\udb81\udd81",
            low: "\uf026",
            mid: "\uf027",
            high: "\uf028"
        })
    readonly property var brightnessGlyphs: ({
            low: "\udb80\udcde",
            mid: "\udb80\udcdf",
            high: "\udb80\udce0"
        })

    // Media glyphs: placeholder art and transport controls.
    readonly property string glyphMusic: "\udb81\udf5a"
    readonly property string glyphPrev: "\uf048"
    readonly property string glyphNext: "\uf051"
    readonly property string glyphPlay: "\uf04b"
    readonly property string glyphPause: "\uf04c"
}

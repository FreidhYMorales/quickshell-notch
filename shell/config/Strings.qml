pragma Singleton

import Quickshell

// Every user-visible text lives here.
Singleton {
    readonly property string workspaces: "Workspaces"
    readonly property string brightness: "Brightness"
    readonly property string volume: "Volume"
    readonly property string controlCenter: "Control center"
    readonly property string center: "Notch"
    // Lock screen authentication.
    readonly property string lockLoginFailed: "Login failed"
    // Shown by `systemd-inhibit --list` for the notch's sleep inhibitor.
    readonly property string sleepInhibitReason: "Lock the session before sleep"
    // Control center profile: "up 3h 12m".
    readonly property string uptimePrefix: "up "
    // Control center notifications section; %1 = how many.
    readonly property string notificationsTitle: "Notifications (%1)"
    readonly property string noNotifications: "No notifications"
    readonly property string wallpaperTitle: "Wallpaper"
    readonly property string wallpaperEmpty: "No wallpapers found"
    readonly property string wallpaperVideo: "Video"
    readonly property string wallpaperHint: "← → Browse · Enter Apply · Esc Back"
    readonly property string themeTitle: "Theme"
    readonly property string keybindsTitle: "Keybinds"
    readonly property string keybindsUnavailable: "Keybinds unavailable"
    readonly property string webappTitle: "Webapp"
    readonly property string screensaverTitle: "Screensaver"
    readonly property string securityTitle: "Security"
    readonly property string securityFingerprintUnlock: "Fingerprint unlock"
    readonly property string securityRegistered: "Registered fingers"
    readonly property string securityAdd: "Add a finger"
    readonly property string securityHandHint: "Click a bright print to remove it, or a dim one to add it."
    readonly property string securityEnrolling: "Enrolling %1"
    readonly property string securityTouches: "Touches: %1"
    // Enrollment hints keyed by fprintd-enroll's status (without "enroll-").
    readonly property var enrollHints: ({
            start: "Touch the fingerprint sensor",
            again: "Touch the sensor again",
            "retry-scan": "Try scanning again",
            "swipe-too-short": "Swipe was too short, try again",
            "too-fast": "Too fast, try again slower",
            "finger-not-centered": "Center your finger on the sensor",
            "remove-and-retry": "Remove your finger and try again"
        })
    readonly property string enrollRetry: "Try again"
    readonly property string securityCancel: "Cancel"
    readonly property string securityRemove: "Remove"
    // fprintd finger names as the security view shows them.
    readonly property var fingerLabels: ({
            "left-thumb": "Left thumb",
            "left-index-finger": "Left index",
            "left-middle-finger": "Left middle",
            "left-ring-finger": "Left ring",
            "left-little-finger": "Left little",
            "right-thumb": "Right thumb",
            "right-index-finger": "Right index",
            "right-middle-finger": "Right middle",
            "right-ring-finger": "Right ring",
            "right-little-finger": "Right little"
        })
    // Screensaver view: the three idle stages and their minutes (%1).
    readonly property var idleStageNames: ["Screensaver", "Lock", "Suspend"]
    readonly property string idleOff: "Off"
    readonly property string idleMinutes: "%1 min"
    readonly property string idleLess: "−"
    readonly property string idleMore: "+"
    readonly property string idleSameAsDesktop: "Same as desktop wallpaper"
    readonly property string idleSwitchOn: "󰄲"
    readonly property string idleSwitchOff: "󰄱"
    readonly property string webappInstall: "Install"
    readonly property string webappNamePlaceholder: "Web app name"
    readonly property string webappUrlPlaceholder: "https://example.com"
    readonly property string webappInstalled: "Installed"
    readonly property string webappInstallFailed: "Installation failed"
    readonly property string webappNameMissing: "Name is required"
    readonly property string webappNameUnsafe: "Use a name without / or a leading dot"
    readonly property string webappUrlMissing: "URL is required"
    readonly property string webappUrlInvalid: "Use an http or https URL"
    readonly property string webappUnavailable: "Webapp unavailable"
    // The helper the form runs, as the old shell did: it writes the desktop
    // entry and fetches the favicon.
    readonly property string webappHelper: "webapp-install"
    readonly property string themeHint: "↑ ↓ Choose · Enter Apply · Tab Light/Dark · Esc Back"
    // Icons on the knob of the theme view's app Light/Dark switch.
    readonly property string themeLight: "󰖨"
    readonly property string themeDark: "󰽥"
    readonly property string themeActiveMark: "✓"
    // Friendly names for the nine matugen scheme types, keyed by id.
    readonly property var themeModeNames: ({
            "scheme-tonal-spot": "Default",
            "scheme-monochrome": "Mono",
            "scheme-vibrant": "Vibrant",
            "scheme-expressive": "Expressive",
            "scheme-fidelity": "Fidelity",
            "scheme-content": "Content",
            "scheme-neutral": "Neutral",
            "scheme-rainbow": "Rainbow",
            "scheme-fruit-salad": "Fruit Salad"
        })
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
        },
        {
            name: "Webapp",
            glyph: "󰖟",
            description: "Install a website as a desktop web app."
        },
        {
            name: "Screensaver",
            glyph: "󰒲",
            description: "Set the screensaver, lock and suspend times and the screensaver wallpaper."
        },
        {
            name: "Security",
            glyph: "󰈷",
            description: "Turn fingerprint unlock on or off and manage your registered fingers."
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
    // Power profile tile: one glyph per profile, plus the caffeine tile.
    readonly property var profileGlyphs: ({
            performance: "󰓅",
            balanced: "󰚀",
            "power-saver": "󰌪"
        })
    readonly property string glyphCaffeine: "󰅶"
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
    // Full names for the expanded month view's title.
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    // Month view header arrows, as in the old bar's calendar.
    readonly property string glyphMonthPrev: "󰅁"
    readonly property string glyphMonthNext: "󰅂"

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
    // Control center battery card: state line keyed by Battery.layer, the
    // detail pieces (%1 = formatted value) and their separator.
    readonly property var batteryStates: ({
            none: "Discharging",
            low: "Low",
            charging: "Charging",
            plugged: "Plugged in",
            full: "Full"
        })
    readonly property string batteryTimeLeft: "%1 left"
    readonly property string batteryTimeToFull: "%1 to full"
    readonly property string batteryRate: "%1 W"
    readonly property string batteryWh: "%1 / %2 Wh"
    readonly property string batteryLimit: "limit %1%"
    readonly property string batteryHealth: "health %1"
    readonly property string batteryCycles: "%1 cyc"
    readonly property string batteryDetailSeparator: " · "
    // Battery card stat captions and the value shown when one is missing.
    readonly property string batteryDrawLabel: "DRAW"
    readonly property string batteryEnergyLabel: "ENERGY"
    readonly property string batteryWearLabel: "WEAR"
    readonly property string batteryUnknown: "–"
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
    readonly property string glyphBatteryHalf: "\uf242"
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

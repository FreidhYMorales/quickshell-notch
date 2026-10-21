pragma Singleton

import Quickshell
import "../logic/calendar.mjs" as Calendar

// Wall clock at minute precision; no seconds are shown anywhere.
Singleton {
    id: root

    // Fired once when the calendar day changes (midnight).
    signal dayChanged

    readonly property date now: clock.date
    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth() + 1
    readonly property int dayOfMonth: now.getDate()
    readonly property int hours: now.getHours()
    readonly property int minutes: now.getMinutes()
    readonly property string dayKey: Calendar.dayKey({
        year: year,
        month: month,
        day: dayOfMonth
    })

    onDayKeyChanged: dayChanged()

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}

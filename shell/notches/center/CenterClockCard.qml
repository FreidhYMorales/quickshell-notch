pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/calendar.mjs" as Calendar
import "../../logic/format.mjs" as Format

// Clock card: large 24-hour clock above a week strip centred on today. The
// strip depends on Time's date fields, so it rolls over at midnight; days
// fade towards both edges and today is marked by its text colour (no pill).
Rectangle {
    id: root

    objectName: "calendar-card"

    property var scheme: Colours.fallback
    // Monitor this card's clicks are dispatched for.
    property string monitor: ""
    property color cardColor: Colours.background
    // Whole weeks the strip is scrolled away from today; scrolling down is later.
    property int offset: 0

    readonly property var today: ({
            year: Time.year,
            month: Time.month,
            day: Time.dayOfMonth
        })
    readonly property var week: Calendar.weekStrip(Calendar.shiftDays(today, 7 * offset), Limits.weekRadius, today)

    radius: Layout.cardRadius
    color: cardColor

    // Scrolling anywhere over the card moves the calendar: down is later.
    function scroll(dy: real) {
        if (dy !== 0)
            CenterStore.dispatch({
                type: "CalendarScroll",
                monitor: root.monitor,
                steps: dy < 0 ? 1 : -1
            });
    }

    WheelHandler {
        onWheel: event => root.scroll(event.angleDelta.y)
    }

    Column {
        anchors.centerIn: parent
        spacing: Layout.rowGap

        Text {
            objectName: "calendar-clock"
            anchors.horizontalCenter: parent.horizontalCenter
            text: Format.clock(Time.hours, Time.minutes)
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.display

            // Clicking the clock brings the strip back to today.
            TapHandler {
                onTapped: CenterStore.dispatch({
                    type: "CalendarToday",
                    monitor: root.monitor
                })
            }
        }

        Row {
            objectName: "calendar-week"
            anchors.horizontalCenter: parent.horizontalCenter

            // Clicking the strip opens the month view.
            TapHandler {
                onTapped: CenterStore.dispatch({
                    type: "CalendarMonth",
                    monitor: root.monitor
                })
            }

            Repeater {
                model: root.week

                Item {
                    id: cell

                    required property var modelData
                    required property int index

                    width: (root.width - 2 * Layout.weekCardPad) / root.week.length
                    height: dayColumn.implicitHeight + Layout.weekCardPad
                    opacity: 1 - Math.abs(index - Limits.weekRadius) / (Limits.weekRadius + 1)

                    Column {
                        id: dayColumn

                        anchors.centerIn: parent

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Strings.weekdays[cell.modelData.weekday]
                            color: cell.modelData.today ? root.scheme.primary : root.scheme.muted
                            font.family: Fonts.family
                            font.pixelSize: Fonts.small
                            font.bold: cell.modelData.today
                        }

                        Text {
                            objectName: cell.index === Limits.weekRadius ? "calendar-centre" : ""
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cell.modelData.day
                            color: cell.modelData.today ? root.scheme.primary : root.scheme.onSurface
                            font.family: Fonts.family
                            font.pixelSize: Fonts.body
                            font.bold: cell.modelData.today
                        }
                    }
                }
            }
        }
    }
}

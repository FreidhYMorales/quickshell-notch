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

    property var scheme: Colours.fallback
    // Monitor this card's clicks are dispatched for.
    property string monitor: ""
    property color cardColor: Colours.background

    readonly property var week: Calendar.weekStrip({
        year: Time.year,
        month: Time.month,
        day: Time.dayOfMonth
    }, Limits.weekRadius)

    radius: Layout.cardRadius
    color: cardColor

    Column {
        anchors.centerIn: parent
        spacing: Layout.rowGap

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Format.clock(Time.hours, Time.minutes)
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.display
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

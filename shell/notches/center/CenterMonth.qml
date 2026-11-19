pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/calendar.mjs" as Calendar

// Month view of the expanded notch: "Mon YYYY" title, weekday header and a
// six-week Monday-first grid. Today is marked like in the week strip; days
// outside the month are dimmed. `offset` counts months from today's month.
Item {
    id: root

    property var scheme: Colours.fallback
    property int offset: 0

    readonly property var today: ({
            year: Time.year,
            month: Time.month,
            day: Time.dayOfMonth
        })
    readonly property var shown: Calendar.shiftMonth({
        year: Time.year,
        month: Time.month
    }, offset)
    readonly property var grid: Calendar.monthGrid(shown, today)
    readonly property real cellWidth: width / 7

    Column {
        anchors.fill: parent
        spacing: Layout.rowGap

        Text {
            objectName: "calendar-title"
            text: Strings.months[root.shown.month - 1] + " " + root.shown.year
            color: root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.body
            font.bold: true
        }

        Row {
            Repeater {
                model: Strings.weekdays

                Text {
                    required property string modelData

                    width: root.cellWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: root.scheme.muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.small
                }
            }
        }

        Grid {
            columns: 7

            Repeater {
                model: root.grid

                Text {
                    required property var modelData

                    objectName: modelData.today ? "calendar-today" : "calendar-day"
                    width: root.cellWidth
                    height: Layout.monthCellHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.day
                    color: modelData.today ? root.scheme.primary : root.scheme.onSurface
                    opacity: modelData.inMonth ? 1 : Colours.dimAlpha
                    font.family: Fonts.family
                    font.pixelSize: Fonts.body
                    font.bold: modelData.today
                }
            }
        }
    }
}

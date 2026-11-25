pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../../logic/calendar.mjs" as Calendar

// Month view of the expanded notch, laid out like the old bar's calendar: a
// header with the previous/next arrows around the "Month YYYY" title, the
// weekday labels and a six-week Monday-first grid. Today sits on a filled
// accent square; days outside the month are faded. `offset` counts months
// from today's month.
Item {
    id: root

    objectName: "calendar-month-view"

    property var scheme: Colours.fallback
    // Monitor this view's clicks are dispatched for.
    property string monitor: ""
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
    readonly property real gridWidth: Math.min(width, Layout.monthGridWidth)
    readonly property real cellWidth: gridWidth / 7

    function step(steps: int) {
        CenterStore.dispatch({
            type: "CalendarScroll",
            monitor: root.monitor,
            steps: steps
        });
    }

    // Scrolling anywhere over the month pages it: down is later.
    function scroll(dy: real) {
        if (dy !== 0)
            step(dy < 0 ? 1 : -1);
    }

    WheelHandler {
        onWheel: event => root.scroll(event.angleDelta.y)
    }

    onVisibleChanged: if (visible)
        forceActiveFocus()

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.gridWidth
        height: parent.height
        spacing: Layout.monthGap

        Item {
            width: root.gridWidth
            height: Layout.monthHeaderHeight

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Layout.monthGap

                Text {
                    objectName: "calendar-prev"
                    width: Layout.monthArrow
                    horizontalAlignment: Text.AlignHCenter
                    text: Strings.glyphMonthPrev
                    color: root.scheme.onSurface
                    font.family: Fonts.family
                    font.pixelSize: Fonts.control

                    TapHandler {
                        onTapped: root.step(-1)
                    }
                }
            }

            // Clicking the title brings the grid back to this month.
            Text {
                objectName: "calendar-title"
                anchors.centerIn: parent
                text: Strings.monthNames[root.shown.month - 1] + " " + root.shown.year
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.title
                font.weight: Font.Medium

                TapHandler {
                    onTapped: CenterStore.dispatch({
                        type: "CalendarToday",
                        monitor: root.monitor
                    })
                }
            }

            Text {
                objectName: "calendar-next"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Layout.monthArrow
                horizontalAlignment: Text.AlignHCenter
                text: Strings.glyphMonthNext
                color: root.scheme.onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.control

                TapHandler {
                    onTapped: root.step(1)
                }
            }
        }

        Row {
            width: root.gridWidth

            Repeater {
                model: Strings.weekdays

                Text {
                    required property string modelData

                    width: root.cellWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: root.scheme.muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.body
                }
            }
        }

        Grid {
            objectName: "calendar-grid"
            width: root.gridWidth
            columns: 7

            Repeater {
                model: root.grid

                Item {
                    id: cell

                    required property var modelData

                    width: root.cellWidth
                    height: Layout.monthCellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: Layout.monthToday
                        height: Layout.monthToday
                        radius: Layout.monthTodayRadius
                        visible: cell.modelData.today
                        color: root.scheme.primary
                    }

                    Text {
                        objectName: cell.modelData.today ? "calendar-today" : "calendar-day"
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        color: cell.modelData.today ? Colours.background : root.scheme.onSurface
                        opacity: cell.modelData.inMonth ? 1 : Colours.outsideAlpha
                        font.family: Fonts.family
                        font.pixelSize: Fonts.title
                    }
                }
            }
        }
    }
}

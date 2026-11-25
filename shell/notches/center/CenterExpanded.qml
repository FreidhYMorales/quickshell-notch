import QtQuick
import "../../components"
import "../../config"
import "../../services"

// Expanded centre notch content: media column on the left (only with a
// player) and the clock card on the right. Replaces the idle row.
Item {
    id: root

    property var screen: null
    // The expanded view's calendar: { view: "week" | "month", offset }.
    property var calendar: null
    property bool keyboardMode: false
    readonly property bool month: calendar !== null && calendar.view === "month"

    focus: true

    function focusControls() {
        if (root.month)
            return;
        if (Mpris.hasPlayer)
            media.focusFirst();
        else
            root.forceActiveFocus();
    }

    onKeyboardModeChanged: if (keyboardMode)
        focusTimer.restart()
    onVisibleChanged: if (visible && keyboardMode)
        focusTimer.restart()
    onMonthChanged: if (!month && keyboardMode)
        focusTimer.restart()

    function handleEscape() {
        if (root.month) {
            CenterStore.dispatch({
                type: "CalendarBack",
                monitor: root.screen ? root.screen.name : ""
            });
            Qt.callLater(root.forceActiveFocus);
        } else {
            CenterStore.dispatch({
                type: "ExpandedClose",
                monitor: root.screen ? root.screen.name : ""
            });
        }
    }

    Keys.onEscapePressed: event => {
        event.accepted = true;
        root.handleEscape();
    }

    readonly property var scheme: Colours.paletteFor(screen)
    // What a visible `!` adds on each side (CenterLayout.expandedWidth).
    readonly property int markExtent: mark.visible ? Layout.expandedGap + mark.width : 0

    NotchEarShape {
        anchors.fill: parent
        accentColor: root.scheme.primary
    }

    Item {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Layout.earRadius + Layout.expandedPad + root.markExtent
        anchors.rightMargin: Layout.earRadius + Layout.expandedPad + root.markExtent
        anchors.topMargin: Layout.expandedPad
        anchors.bottomMargin: Layout.expandedPad

        CenterMedia {
            id: media

            anchors.left: parent.left
            anchors.right: card.left
            anchors.rightMargin: Layout.expandedGap
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.month ? 0 : 1
            visible: Mpris.hasPlayer && opacity > 0
            scheme: root.scheme
            keyboardMode: root.keyboardMode && !root.month

            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: !root.month ? Timings.calendarMorph / 2 : 0
                    }
                    NumberAnimation {
                        duration: Timings.calendarMorph / 2
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }

        // Grows from its column to the whole notch while the month opens,
        // and shrinks back when it closes.
        CenterClockCard {
            id: card

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            x: parent.width - width
            width: root.month || !Mpris.hasPlayer ? parent.width : Layout.clockCardWidth
            open: root.month
            scheme: root.scheme

            Behavior on width {
                Anim {
                    duration: Timings.calendarMorph
                    easing.type: Easing.InOutCubic
                }
            }
            monitor: root.screen ? root.screen.name : ""
            offset: root.calendar !== null && root.calendar.view === "week" ? root.calendar.offset : 0
            cardColor: Colours.cardFor(root.screen)
        }

        // The month fades in over the grown card; Esc closes it.
        CenterMonth {
            anchors.fill: parent
            opacity: root.month ? 1 : 0
            visible: opacity > 0
            focus: root.month
            scheme: root.scheme

            // Shows in the second half of opening; leaves first when closing.
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: root.month ? Timings.calendarMorph / 2 : 0
                    }
                    NumberAnimation {
                        duration: Timings.calendarMorph / 2
                        easing.type: Easing.InOutCubic
                    }
                }
            }
            monitor: root.screen ? root.screen.name : ""
            offset: root.month ? root.calendar.offset : 0
        }
    }

    Timer {
        id: focusTimer

        interval: 100
        repeat: false
        onTriggered: if (root.visible && root.keyboardMode)
            root.focusControls()
    }

    // Waiting criticals: a round `!` button in its own column right of the card.
    Rectangle {
        id: mark

        anchors.left: content.right
        anchors.leftMargin: Layout.expandedGap
        anchors.top: content.top
        width: Layout.criticalButton
        height: Layout.criticalButton
        radius: Layout.criticalButton / 2
        color: Colours.cardFor(root.screen)
        visible: Notifs.pinned.length > 0

        CriticalMark {
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifs.reopen()
        }
    }
}

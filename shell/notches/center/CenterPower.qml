pragma ComponentBehavior: Bound

import QtQuick
import "../../components"
import "../../config"
import "../../logic/powerMenu.mjs" as PowerMenu

// Power menu in the centre notch: one row of action icons (the selected one
// highlighted) over a bar that fills while a session action is held.
Item {
    id: root

    property var screen: null
    property var view: ({})

    readonly property var scheme: Colours.paletteFor(screen)
    readonly property string selected: view.sub ?? PowerMenu.ACTIONS[0]
    readonly property bool holding: view.hold != null

    NotchEarShape {
        anchors.fill: parent
    }

    function send(event) {
        CenterStore.dispatch(event);
    }

    // Enter fires lock/suspend or starts a hold; its release cancels an
    // unfinished hold. Auto-repeat never restarts anything.
    focus: visible
    onVisibleChanged: if (visible)
        forceActiveFocus()
    Keys.onPressed: event => {
        event.accepted = true;
        if (event.isAutoRepeat)
            return;
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_H:
        case Qt.Key_Up:
        case Qt.Key_K:
            return send({
                type: "PowerMove",
                step: -1
            });
        case Qt.Key_Right:
        case Qt.Key_L:
        case Qt.Key_Down:
        case Qt.Key_J:
            return send({
                type: "PowerMove",
                step: 1
            });
        case Qt.Key_Return:
        case Qt.Key_Enter:
            return press(root.selected);
        case Qt.Key_Escape:
            return send({
                type: "Close",
                monitor: root.screen.name
            });
        }
        event.accepted = false;
    }
    Keys.onReleased: event => {
        if (!event.isAutoRepeat && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter))
            send({
                type: "HoldCancel"
            });
    }

    function press(action) {
        if (PowerMenu.needsHold(action))
            send({
                type: "HoldStart",
                action: action
            });
        else
            send({
                type: "PowerActivate",
                action: action
            });
    }

    Row {
        anchors.centerIn: parent
        spacing: Layout.expandedPad * 2

        Repeater {
            model: PowerMenu.ACTIONS

            Text {
                required property string modelData

                text: Strings.powerIcons[modelData]
                color: modelData === root.selected ? root.scheme.primary : root.scheme.muted
                font.family: Fonts.family
                font.pixelSize: Fonts.control

                // Press and hold like Enter; releasing early cancels.
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Layout.expandedPad
                    onPressed: root.press(parent.modelData)
                    onReleased: root.send({
                        type: "HoldCancel"
                    })
                    onCanceled: root.send({
                        type: "HoldCancel"
                    })
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Layout.earRadius
        anchors.bottomMargin: Layout.expandedPad
        height: Layout.powerBarHeight
        width: (parent.width - 2 * Layout.earRadius) * progress
        visible: root.holding
        color: root.scheme.primary

        property real progress: 0

        // Restarts from empty each time a hold begins; the store's timer decides.
        NumberAnimation on progress {
            running: root.holding
            from: 0
            to: 1
            duration: Timings.holdConfirm
        }
    }
}

import QtQuick
import "../../components"
import "../../config"
import "../../logic/centerLayout.mjs" as CenterLayout
import "../../services"

// Centre notch (slot c), one per monitor. The view comes from the shared
// CenterStore. One shape item is both the input mask and the hover zone; its
// width follows the battery layer (symmetric, so the clock stays put) when
// idle, and the player presence when expanded; it animates between the two.
NotchSurface {
    id: root

    readonly property var view: CenterStore.viewFor(screen.name)
    readonly property int idleW: CenterLayout.idleWidth({
        base: idle.baseWidth,
        side: idle.sideNeed,
        layer: idle.batteryLayer,
        dot: idle.dotExtent,
        max: slot.width
    })
    readonly property bool toast: view.mode === "toast"
    readonly property var size: toast ? CenterLayout.toastShape({
        expanded: view.toast.expanded,
        widths: {
            compact: Layout.toastWidth,
            expanded: Layout.toastExpandedWidth
        },
        heights: {
            compact: Layout.idleHeight,
            expanded: Layout.toastExpandedHeight
        },
        max: slot.width
    }) : view.mode === "polkit" ? {
        width: root.polkitWidth,
        height: Math.max(Layout.polkitMinHeight, polkitForm.implicitHeight + 2 * Layout.polkitPad)
    } : CenterLayout.shapeFor(view.mode, {
        idle: idleW,
        expanded: CenterLayout.expandedWidth({
            hasPlayer: Mpris.hasPlayer,
            full: Layout.expandedWidth,
            clockOnly: Layout.expandedClockWidth,
            mark: expandedView.markExtent,
            max: slot.width
        }),
        power: Layout.powerWidth,
        launcher: Layout.launcherWidth
    }, {
        idle: Layout.idleHeight,
        expanded: Layout.expandedHeight,
        power: Layout.powerHeight,
        launcher: launcherView.implicitHeight
    })
    readonly property bool expanded: view.mode === "expanded"
    readonly property bool power: view.mode === "power"
    readonly property bool launcher: view.mode === "launcher"
    readonly property bool polkit: view.mode === "polkit"
    readonly property var scheme: Colours.paletteFor(screen)
    readonly property int polkitWidth: CenterStore.state.global.polkit?.flowId?.isResponseRequired === false ? Layout.polkitWideWidth : Layout.polkitWidth
    // Same tint as the notifications card, for the polkit field and idle buttons.
    readonly property color tint: {
        const p = Qt.color(scheme.primary);
        return Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
    }

    slotName: "c"
    // The launcher is taller than the expanded slot; the window is masked, so
    // the extra height is invisible until the launcher fills it.
    minHeight: Math.max(launcherView.implicitHeight, root.polkit ? root.size.height : 0)
    wantsKeyboard: view.keyboardFocus === "exclusive"
    // Only the visible shape takes input; clicks beside it pass through.
    maskItem: shape

    // The one place a response leaves the notch: the accept button and Enter.
    function submitResponse() {
        const flow = CenterStore.state.global.polkit?.flowId;
        if (!flow || !flow.isResponseRequired)
            return;
        const response = polkitInput.text;
        polkitInput.text = "";
        flow.submit(response);
    }

    Item {
        id: shape

        width: root.shown ? root.size.width : 0
        height: root.size.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        clip: true

        // Keeps the zone hovered while a child (power icons) takes the hover.
        HoverHandler {
            id: shapeHover
        }

        Behavior on width {
            Anim {}
        }

        Behavior on height {
            Anim {}
        }

        CenterIdle {
            id: idle

            anchors.fill: parent
            visible: !root.expanded && !root.toast && !root.power && !root.launcher && !root.polkit
            screen: root.screen
            view: root.view
        }

        CenterToast {
            anchors.fill: parent
            visible: root.toast
            screen: root.screen
            expanded: root.toast && root.view.toast.expanded
        }

        CenterPower {
            anchors.fill: parent
            visible: root.power
            screen: root.screen
            view: root.view
        }

        CenterLauncher {
            id: launcherView

            anchors.fill: parent
            visible: root.launcher
            screen: root.screen
            view: root.view
        }

        // Polkit draws no mode content of its own, so the card is drawn here and
        // the form keeps its own padding inside it.
        NotchEarShape {
            objectName: "polkitBackground"
            anchors.fill: parent
            visible: root.polkit
        }

        Column {
            id: polkitForm

            // Escape cancels in both modes: the field passes it up, and the
            // fingerprint block holds focus when there is no field.
            Keys.onEscapePressed: CenterStore.dispatch({
                type: "PolkitCancel"
            })
            width: root.polkitWidth - 2 * Layout.polkitSidePad
            x: (parent.width - width) / 2
            anchors.top: parent.top
            anchors.topMargin: Layout.polkitPad
            spacing: Layout.polkitGap
            visible: root.polkit

            Text {
                id: polkitMessage

                objectName: "polkitMessage"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.polkit ? CenterStore.state.global.polkit.flowId.message : ""
                color: Colours.paletteFor(root.screen).onSurface
                font.family: Fonts.family
                font.pixelSize: Fonts.idleClock
            }

            // Fingerprint icon with a line sweeping over it while the reader waits.
            Item {
                width: parent.width
                focus: visible
                height: polkitFingerprint.implicitHeight
                visible: root.polkit && CenterStore.state.global.polkit.flowId.isResponseRequired === false

                Text {
                    id: polkitFingerprint

                    objectName: "polkitFingerprintGlyph"
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Strings.glyphFingerprint
                    color: root.scheme.primary
                    opacity: Colours.dimAlpha
                    font.family: Fonts.family
                    font.pixelSize: Fonts.polkitFingerprint
                }

                Rectangle {
                    id: polkitScan

                    objectName: "polkitFingerprintScan"
                    x: polkitFingerprint.x
                    width: polkitFingerprint.implicitWidth
                    height: Layout.polkitScanLine
                    radius: height / 2
                    color: root.scheme.primary

                    SequentialAnimation on y {
                        running: polkitScan.visible
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: 0
                            to: polkitFingerprint.implicitHeight - Layout.polkitScanLine
                            duration: Timings.polkitScan
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            from: polkitFingerprint.implicitHeight - Layout.polkitScanLine
                            to: 0
                            duration: Timings.polkitScan
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }

            Text {
                id: polkitError

                objectName: "polkitError"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: text !== ""
                text: root.polkit ? CenterStore.state.global.polkit.flowId.supplementaryMessage ?? "" : ""
                color: root.polkit && CenterStore.state.global.polkit.flowId.supplementaryIsError ? Colours.critical : Colours.paletteFor(root.screen).muted
                font.family: Fonts.family
                font.pixelSize: Fonts.idleClock
            }

            Row {
                id: polkitResponse

                x: (parent.width - width) / 2
                spacing: Layout.polkitGap
                // Cancel is always offered; the field and Authenticate only when a
                // response is required (a fingerprint prompt has neither).
                visible: root.polkit

                Rectangle {
                    id: polkitField

                    visible: root.polkit && CenterStore.state.global.polkit.flowId.isResponseRequired
                    onVisibleChanged: {
                        if (!visible)
                            polkitInput.text = "";
                    }
                    objectName: "polkitField"
                    width: Layout.polkitFieldWidth
                    height: Layout.polkitFieldHeight
                    radius: height / 2
                    color: root.tint

                    TextInput {
                        id: polkitInput

                        objectName: "polkitInput"
                        anchors.fill: parent
                        anchors.leftMargin: Layout.polkitFieldPad
                        anchors.rightMargin: Layout.polkitFieldPad
                        verticalAlignment: TextInput.AlignVCenter
                        focus: polkitField.visible
                        onVisibleChanged: if (visible)
                            forceActiveFocus()
                        echoMode: TextInput.Password
                        onAccepted: root.submitResponse()
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.idleClock
                    }
                }

                Rectangle {
                    id: polkitCancel

                    objectName: "polkitCancelButton"
                    width: Layout.polkitButton
                    height: Layout.polkitButton
                    radius: height / 2
                    color: cancelHover.hovered ? root.scheme.primary : root.tint

                    Behavior on color {
                        ColorAnimation {
                            duration: Timings.animNormal
                        }
                    }

                    Text {
                        objectName: "polkitCancelGlyph"
                        anchors.centerIn: parent
                        text: Strings.glyphClose
                        color: cancelHover.hovered ? Colours.background : root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.title

                        Behavior on color {
                            ColorAnimation {
                                duration: Timings.animNormal
                            }
                        }
                    }

                    HoverHandler {
                        id: cancelHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: CenterStore.dispatch({
                            type: "PolkitCancel"
                        })
                    }
                }

                Rectangle {
                    id: polkitAccept

                    visible: polkitField.visible
                    objectName: "polkitAcceptButton"
                    width: Layout.polkitButton
                    height: Layout.polkitButton
                    radius: height / 2
                    color: acceptHover.hovered ? root.scheme.primary : root.tint

                    Behavior on color {
                        ColorAnimation {
                            duration: Timings.animNormal
                        }
                    }

                    Text {
                        objectName: "polkitAcceptGlyph"
                        anchors.centerIn: parent
                        text: Strings.glyphCheck
                        color: acceptHover.hovered ? Colours.background : root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.title

                        Behavior on color {
                            ColorAnimation {
                                duration: Timings.animNormal
                            }
                        }
                    }

                    HoverHandler {
                        id: acceptHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.submitResponse()
                    }
                }
            }
        }

        CenterExpanded {
            id: expandedView

            anchors.fill: parent
            visible: root.expanded
            screen: root.screen
        }
    }

    // Below the content so the power icons get their own hover.
    NotchZone {
        z: -1
        anchors.fill: shape
        alsoHovered: shapeHover.hovered
        onHoverChanged: on => CenterStore.dispatch({
                type: "Hover",
                monitor: root.screen.name,
                on: on
            })
    }
}

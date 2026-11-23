import QtQuick
import "../../components"
import "../../config"
import "../../logic/centerLayout.mjs" as CenterLayout
import "../../logic/centerView.mjs" as CenterView
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
    // The greeter reads the published width to compress into the same shape.
    function reportIdleWidth() {
        CenterStore.setIdleNotchWidth(screen.name, idleW);
        Theme.setIdleNotchWidth(screen.name, idleW);
    }
    onIdleWChanged: root.reportIdleWidth()
    Component.onCompleted: root.reportIdleWidth()

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
    } : CenterLayout.shapeFor(CenterView.shapeMode(view), {
        idle: idleW,
        expanded: expandedW,
        month: expandedW,
        power: Layout.powerWidth,
        launcher: Layout.launcherWidth
    }, {
        idle: Layout.idleHeight,
        expanded: Layout.expandedHeight,
        month: Layout.monthHeight,
        power: Layout.powerHeight,
        launcher: launcherView.implicitHeight
    })
    readonly property bool expanded: view.mode === "expanded"
    readonly property bool month: CenterView.shapeMode(view) === "month"
    // An open month keeps the expanded width and only grows downwards.
    readonly property int expandedW: CenterLayout.expandedWidth({
        hasPlayer: Mpris.hasPlayer,
        full: Layout.expandedWidth,
        clockOnly: Layout.expandedClockWidth,
        mark: expandedView.markExtent,
        max: slot.width
    })
    readonly property bool power: view.mode === "power"
    readonly property bool launcher: view.mode === "launcher"
    readonly property bool polkit: view.mode === "polkit"
    // These modes switch in at once and hide the idle and expanded layers.
    readonly property bool takenOver: toast || power || launcher || polkit
    readonly property var scheme: Colours.paletteFor(screen)
    // The current polkit request wants typed input (false: fingerprint and the like).
    readonly property bool polkitNeedsResponse: polkit && CenterStore.state.global.polkit.flowId.isResponseRequired === true
    readonly property int polkitWidth: CenterStore.state.global.polkit?.flowId?.isResponseRequired === false ? Layout.polkitWideWidth : Layout.polkitWidth
    // Same tint as the notifications card, for the polkit field and idle buttons.
    readonly property color tint: {
        const p = Qt.color(scheme.primary);
        return Qt.rgba(p.r, p.g, p.b, Colours.tileOffAlpha);
    }

    slotName: "c"
    // The launcher is taller than the expanded slot; the window is masked, so
    // the extra height is invisible until the launcher fills it.
    minHeight: Math.max(launcherView.implicitHeight, root.polkit || root.month ? root.size.height : 0)
    wantsKeyboard: view.keyboardFocus === "exclusive"
    // Only the visible shape takes input; clicks beside it pass through.
    maskItem: shape

    // Round glyph button of the polkit prompt (cancel / authenticate).
    component PolkitButton: Rectangle {
        id: button

        property string glyph
        property string glyphName
        signal activated

        width: Layout.polkitButton
        height: Layout.polkitButton
        radius: height / 2
        color: hover.hovered ? root.scheme.primary : root.tint

        Behavior on color {
            ColorAnimation {
                duration: Timings.animNormal
            }
        }

        Text {
            objectName: button.glyphName
            anchors.centerIn: parent
            text: button.glyph
            color: hover.hovered ? Colours.background : root.scheme.onSurface
            font.family: Fonts.family
            font.pixelSize: Fonts.title

            Behavior on color {
                ColorAnimation {
                    duration: Timings.animNormal
                }
            }
        }

        HoverHandler {
            id: hover
        }

        MouseArea {
            anchors.fill: parent
            onClicked: button.activated()
        }
    }

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

        // The month morph is slower than the other shape changes.
        Behavior on height {
            Anim {
                duration: root.month || shape.height > Layout.expandedHeight ? Timings.calendarMorph : Timings.animNormal
                easing.type: root.month || shape.height > Layout.expandedHeight ? Easing.InOutCubic : Easing.OutCubic
            }
        }

        CenterIdle {
            id: idle

            objectName: "center-idle"
            anchors.fill: parent
            // Cross-fades with the expanded layer while the shape morphs.
            opacity: root.expanded ? 0 : 1
            visible: opacity > 0 && !root.takenOver
            screen: root.screen
            view: root.view

            Behavior on opacity {
                Anim {}
            }
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
            accentColor: root.scheme.primary
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

            // The hint (or error) line; a fingerprint prompt has its cancel here.
            Row {
                x: (parent.width - width) / 2
                spacing: Layout.polkitGap
                visible: root.polkit && (polkitError.text !== "" || !root.polkitNeedsResponse)

                Text {
                    id: polkitError

                    objectName: "polkitError"
                    width: Math.min(implicitWidth, polkitForm.width - (root.polkit && !root.polkitNeedsResponse ? Layout.polkitButton + Layout.polkitGap : 0))
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: text !== ""
                    text: root.polkit ? CenterStore.state.global.polkit.flowId.supplementaryMessage ?? "" : ""
                    color: root.polkit && CenterStore.state.global.polkit.flowId.supplementaryIsError ? Colours.critical : Colours.paletteFor(root.screen).muted
                    font.family: Fonts.family
                    font.pixelSize: Fonts.idleClock
                }

                PolkitButton {
                    id: polkitHintCancel
                    visible: root.polkit && !root.polkitNeedsResponse
                    anchors.verticalCenter: parent.verticalCenter
                    objectName: "polkitCancelButton"
                    glyphName: "polkitCancelGlyph"
                    glyph: Strings.glyphClose
                    onActivated: CenterStore.dispatch({
                        type: "PolkitCancel"
                    })
                }
            }

            Row {
                id: polkitResponse

                x: (parent.width - width) / 2
                spacing: Layout.polkitGap
                visible: root.polkitNeedsResponse

                Rectangle {
                    id: polkitField

                    visible: root.polkitNeedsResponse
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
                        focus: root.polkitNeedsResponse
                        onVisibleChanged: if (visible)
                            forceActiveFocus()
                        echoMode: TextInput.Password
                        onAccepted: root.submitResponse()
                        color: root.scheme.onSurface
                        font.family: Fonts.family
                        font.pixelSize: Fonts.idleClock
                    }
                }

                PolkitButton {
                    id: polkitCancel
                    objectName: "polkitCancelButton"
                    glyphName: "polkitCancelGlyph"
                    glyph: Strings.glyphClose
                    onActivated: CenterStore.dispatch({
                        type: "PolkitCancel"
                    })
                }

                PolkitButton {
                    id: polkitAccept
                    objectName: "polkitAcceptButton"
                    glyphName: "polkitAcceptGlyph"
                    glyph: Strings.glyphCheck
                    onActivated: root.submitResponse()
                }
            }
        }

        CenterExpanded {
            id: expandedView

            objectName: "center-expanded"
            anchors.fill: parent
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0 && !root.takenOver
            screen: root.screen
            calendar: root.view.calendar ?? null

            Behavior on opacity {
                Anim {}
            }
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

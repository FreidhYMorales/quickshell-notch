import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"
import "../logic/surfaceLayout.mjs" as SurfaceLayout

// Base for every top-row surface. Fixed size from layoutFor (slot: tl, bl, c,
// vr or tr); content animates inside. Never reserves space, never takes
// keyboard focus unless a view asks for it.
PanelWindow {
    id: root

    // Fills the surface; children go here. Hidden surfaces get an empty mask.
    default property alias content: body.data
    readonly property var slot: SurfaceLayout.layoutFor(screen.width, screen.name, Layout.tokens)[slotName]
    property string slotName: "c"
    property bool shown: true
    property bool wantsKeyboard: false

    anchors {
        top: true
        left: true
    }
    margins.left: slot.x
    implicitWidth: slot.width
    implicitHeight: slot.height
    visible: shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {
        item: body
    }
    WlrLayershell.keyboardFocus: wantsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "notch-" + slotName

    Item {
        id: body

        width: root.shown ? root.width : 0
        height: root.shown ? root.height : 0
    }
}

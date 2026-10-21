import Quickshell
import Quickshell.Wayland
import "../config"

// The only surface that reserves screen space (ADR 0004): invisible, full
// width, idle notch height. Everything else uses ExclusionMode.Ignore.
PanelWindow {
    id: root

    readonly property bool reserve: Flags.reserveSpace && !Flags.smoke

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Layout.idleHeight
    color: "transparent"
    exclusionMode: reserve ? ExclusionMode.Auto : ExclusionMode.Ignore
    exclusiveZone: reserve ? Layout.idleHeight : 0
    focusable: false
    // Empty mask: every click passes through.
    mask: Region {}
    WlrLayershell.namespace: "notch-spacer"
}

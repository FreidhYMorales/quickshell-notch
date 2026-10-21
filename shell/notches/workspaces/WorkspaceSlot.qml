import QtQuick
import Quickshell
import "../../config"
import "../../logic/workspaceStrip.mjs" as Strip

// One strip slot. kind: active (dot, or the new app's icon while flashing),
// app (icon of the last-focused app, else its initial), empty (dash) or
// special (glyph for the special workspace named in `app`).
Item {
    id: root

    property string kind: "empty"
    property string app: ""
    property var scheme: null

    readonly property bool showsApp: (kind === "app" || kind === "active") && app !== ""
    readonly property string icon: showsApp ? Quickshell.iconPath(DesktopEntries.heuristicLookup(app)?.icon ?? "", true) : ""
    readonly property string label: {
        if (kind === "special")
            return Strings.specialGlyphs[app] ?? Strings.glyphSpecial;
        if (showsApp)
            return Strip.appInitial(app, Strings.unknownInitial);
        return kind === "active" ? Strings.symbolActive : Strings.symbolEmpty;
    }

    signal clicked

    implicitWidth: kind === "active" ? Layout.wsSlotActive : Layout.wsSlot
    implicitHeight: Layout.wsSlotActive

    Image {
        anchors.centerIn: parent
        width: Layout.wsIcon
        height: Layout.wsIcon
        sourceSize: Qt.size(Layout.wsIcon, Layout.wsIcon)
        source: root.icon
        visible: root.icon !== ""
    }

    Text {
        anchors.centerIn: parent
        visible: root.icon === ""
        text: root.label
        color: root.kind === "empty" ? root.scheme.muted : (root.kind === "app" ? root.scheme.onSurface : root.scheme.primary)
        font.family: Fonts.family
        font.pixelSize: Fonts.body
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}

import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "PolkitRequest", flowId: { message: "Authentication required", isResponseRequired: true }, monitor: screen.name });
            check.start();
        }
    }
    Timer {
        id: check
        interval: 500
        onTriggered: {
            const cancel = Visual.findNamed(root.target.content, "polkitCancelButton");
            const accept = Visual.findNamed(root.target.content, "polkitAcceptButton");
            const cancelGlyph = Visual.findNamed(root.target.content, "polkitCancelGlyph");
            const acceptGlyph = Visual.findNamed(root.target.content, "polkitAcceptGlyph");
            if (!cancel || !accept || !cancelGlyph || !acceptGlyph) {
                console.error("polkit controls: cancel or authenticate button missing");
                return Qt.exit(1);
            }
            if (cancelGlyph.text === "" || acceptGlyph.text === "") {
                console.error("polkit controls: button glyph missing");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}

import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    function sameTint(actual, expected) {
        const eps = 0.01;
        return Math.abs(actual.r - expected.r) < eps && Math.abs(actual.g - expected.g) < eps && Math.abs(actual.b - expected.b) < eps && Math.abs(actual.a - expected.a) < eps;
    }
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
            const p = Qt.color(root.target.scheme.primary);
            const tint = Qt.rgba(p.r, p.g, p.b, 0.18);
            for (const name of ["polkitField", "polkitCancelButton", "polkitAcceptButton"]) {
                const item = Visual.findNamed(root.target.content, name);
                if (!item) {
                    console.error("polkit tint: " + name + " missing");
                    return Qt.exit(1);
                }
                if (!root.sameTint(item.color, tint)) {
                    console.error("polkit tint: " + name + " is " + item.color + ", expected " + tint);
                    return Qt.exit(1);
                }
            }
            Qt.exit(0);
        }
    }
}

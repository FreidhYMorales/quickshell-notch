import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the launcher in command mode, activates Theme and checks the nine
// rows, the active marker and the preview placeholder before choosing one.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme }', root)

    readonly property var modes: [
        "scheme-tonal-spot",
        "scheme-monochrome",
        "scheme-vibrant",
        "scheme-expressive",
        "scheme-fidelity",
        "scheme-content",
        "scheme-neutral",
        "scheme-rainbow",
        "scheme-fruit-salad"
    ]

    function findCallback(items, name) {
        for (const item of items) {
            if (item.visible && typeof item[name] === "function")
                return item;
            const found = item.children && item.children.length !== undefined ? findCallback(item.children, name) : null;
            if (found)
                return found;
        }
        return null;
    }

    Timer {
        interval: 2500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "LauncherToggle",
                monitor: screen.name
            });
            root.center.store.dispatch({
                type: "LauncherQuery",
                text: ">theme"
            });
            open.start();
        }
    }

    Timer {
        id: open

        interval: 800
        onTriggered: {
            const launcher = root.findCallback(root.target.content, "launch");
            if (!launcher || !Visual.findText(root.target.content, "Theme"))
                return Qt.exit(2);
            launcher.launch(0);
            check.start();
        }
    }

    Timer {
        id: check

        interval: 800
        onTriggered: {
            const view = root.findCallback(root.target.content, "choose");
            if (!view)
                return Qt.exit(3);
            for (const mode of root.modes) {
                if (!Visual.findNamed(root.target.content, "theme-row-" + mode)) {
                    console.error("theme view: missing row " + mode);
                    return Qt.exit(1);
                }
            }
            if (!Visual.findNamed(root.target.content, "theme-active-" + root.services.theme.mode)) {
                console.error("theme view: no active marker for " + root.services.theme.mode);
                return Qt.exit(1);
            }
            if (Visual.findNamed(root.target.content, "theme-active-scheme-vibrant")) {
                console.error("theme view: wrong active marker");
                return Qt.exit(1);
            }
            if (!Visual.findNamed(root.target.content, "theme-preview")) {
                console.error("theme view: no preview placeholder");
                return Qt.exit(1);
            }
            console.log("theme view: nine rows, active, placeholder");
            view.choose(2);
            closed.start();
        }
    }

    Timer {
        id: closed

        interval: 800
        onTriggered: {
            if (root.center.store.state.global.keyboard !== null) {
                console.error("theme view: launcher still open after choose");
                return Qt.exit(1);
            }
            console.log("theme view: closed after choose");
            Qt.exit(0);
        }
    }
}

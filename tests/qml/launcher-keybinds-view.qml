import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the launcher in command mode, activates Keybinds and checks the view
// lists the registry rows with their key label and description.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    readonly property bool failing: Quickshell.env("NOTCH_FAKE_KEYBINDS") === "fail"

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
                text: ">keybinds"
            });
            open.start();
        }
    }

    Timer {
        id: open

        interval: 800
        onTriggered: {
            const launcher = root.findCallback(root.target.content, "launch");
            if (!launcher || !Visual.findText(root.target.content, "Keybinds"))
                return Qt.exit(2);
            launcher.launch(0);
            check.start();
        }
    }

    Timer {
        id: check

        interval: 1400
        onTriggered: {
            if (root.center.store.state.global.keyboard?.sub !== "keybinds") {
                console.error("keybinds view: not open");
                return Qt.exit(1);
            }
            if (root.failing) {
                if (Visual.findNamed(root.target.content, "keybinds-row-0")) {
                    console.error("keybinds view: broken registry still shows rows");
                    return Qt.exit(1);
                }
                if (!Visual.findText(root.target.content, "Keybinds unavailable")) {
                    console.error("keybinds view: unavailable line missing");
                    return Qt.exit(1);
                }
                console.log("keybinds view: unavailable line shown");
                return Qt.exit(0);
            }
            if (!Visual.findNamed(root.target.content, "keybinds-row-0") || !Visual.findNamed(root.target.content, "keybinds-row-1")) {
                console.error("keybinds view: registry rows missing");
                return Qt.exit(1);
            }
            if (Visual.findNamed(root.target.content, "keybinds-row-2")) {
                console.error("keybinds view: undescribed bind shown");
                return Qt.exit(1);
            }
            if (!Visual.findText(root.target.content, "Super + RETURN") || !Visual.findText(root.target.content, "Open Terminal") || !Visual.findText(root.target.content, "Ctrl + Alt + F")) {
                console.error("keybinds view: key label or description missing");
                return Qt.exit(1);
            }
            if (Visual.findText(root.target.content, "Not available yet")) {
                console.error("keybinds view: unavailable notice still shown");
                return Qt.exit(1);
            }
            console.log("keybinds view: rows with keys and description");
            Qt.exit(0);
        }
    }
}

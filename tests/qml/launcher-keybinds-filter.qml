import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the keybinds view, types in its field and checks the rows narrow to the
// match, that nothing matching shows "No matches", that clearing restores every
// row and that the notch never resizes.
ShellRoot {
    id: root
    property var target: null
    property var field: null
    property real heightBefore: 0
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

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
            if (!launcher)
                return Qt.exit(2);
            launcher.launch(0);
            typed.start();
        }
    }

    Timer {
        id: typed

        interval: 1400
        onTriggered: {
            const launcher = root.findCallback(root.target.content, "launch");
            root.heightBefore = launcher.implicitHeight;
            root.field = Visual.findNamed(root.target.content, "keybinds-field");
            if (!root.field) {
                console.error("keybinds filter: no search field");
                return Qt.exit(1);
            }
            root.field.text = "";
            root.field.insert(0, "browser");
            narrowed.start();
        }
    }

    Timer {
        id: narrowed

        interval: 400
        onTriggered: {
            if (Visual.findNamed(root.target.content, "keybinds-field").text !== "browser") {
                console.error("keybinds filter: query did not reach the field");
                return Qt.exit(1);
            }
            if (!Visual.findText(root.target.content, "Open or focus Browser")) {
                console.error("keybinds filter: matching row missing");
                return Qt.exit(1);
            }
            if (Visual.findNamed(root.target.content, "keybinds-row-1") || Visual.findText(root.target.content, "Open Terminal")) {
                console.error("keybinds filter: unmatched rows still shown");
                return Qt.exit(1);
            }
            if (root.findCallback(root.target.content, "launch").implicitHeight !== root.heightBefore) {
                console.error("keybinds filter: the notch resized while filtering");
                return Qt.exit(1);
            }
            root.field.text = "";
            root.field.insert(0, "zzz");
            empty.start();
        }
    }

    Timer {
        id: empty

        interval: 400
        onTriggered: {
            if (!Visual.findText(root.target.content, "No matches")) {
                console.error("keybinds filter: no empty line");
                return Qt.exit(1);
            }
            if (Visual.findNamed(root.target.content, "keybinds-row-0")) {
                console.error("keybinds filter: rows left under an empty query");
                return Qt.exit(1);
            }
            root.field.text = "";
            cleared.start();
        }
    }

    Timer {
        id: cleared

        interval: 400
        onTriggered: {
            if (!Visual.findNamed(root.target.content, "keybinds-row-0") || !Visual.findNamed(root.target.content, "keybinds-row-1") || !Visual.findNamed(root.target.content, "keybinds-row-2")) {
                console.error("keybinds filter: clearing did not restore the rows");
                return Qt.exit(1);
            }
            console.log("keybinds filter: narrows, empties and restores");
            Qt.exit(0);
        }
    }
}

import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root

    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    property real appListWidth: 0
    property real appResultsHeight: 0
    property real appShapeHeight: 0

    Timer {
        interval: 2500
        running: true

        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "LauncherToggle", monitor: screen.name });
            root.center.store.dispatch({ type: "LauncherQuery", text: "" });
            settle.start();
        }
    }

    Timer {
        id: settle
        interval: 500

        onTriggered: {
            const list = Visual.findNamed(root.target.content, "launcher-results-app-list");
            const results = Visual.findNamed(root.target.content, "launcher-results");
            const shape = Visual.findNamed(root.target.content, "center-notch-shape");
            if (!list || !results || !shape) {
                console.error("launcher transition: missing app results controls");
                return Qt.exit(1);
            }
            root.appListWidth = list.width;
            root.appResultsHeight = results.height;
            root.appShapeHeight = shape.height;
            root.center.store.dispatch({ type: "LauncherQuery", text: ">" });
            sample.start();
        }
    }

    Timer {
        id: sample
        interval: 100

        onTriggered: {
            const list = Visual.findNamed(root.target.content, "launcher-results-command-list");
            const results = Visual.findNamed(root.target.content, "launcher-results");
            const shape = Visual.findNamed(root.target.content, "center-notch-shape");
            if (!list) {
                console.error("launcher transition: command list was not shown");
                return Qt.exit(1);
            }
            if (!shape) {
                console.error("launcher transition: notch shape was not found");
                return Qt.exit(1);
            }
            if (!(list.width < root.appListWidth && list.width > root.appListWidth / 2)) {
                console.error("launcher transition: list width jumped to its target: " + list.width + "/" + root.appListWidth + " parent=" + list.parent.width);
                return Qt.exit(1);
            }
            if (Math.abs(results.height - root.appResultsHeight) > 0.5) {
                console.error("launcher transition: result viewport changed height: " + results.height + "/" + root.appResultsHeight);
                return Qt.exit(1);
            }
            if (Math.abs(shape.height - root.appShapeHeight) > 0.5) {
                console.error("launcher transition: notch changed height: " + shape.height + "/" + root.appShapeHeight);
                return Qt.exit(1);
            }
            if (list.height !== root.appResultsHeight || list.contentHeight <= list.height) {
                console.error("launcher transition: commands do not fit a five-row scroll viewport");
                return Qt.exit(1);
            }
            console.log("launcher transition: five-row viewport keeps notch height stable");
            Qt.exit(0);
        }
    }
}

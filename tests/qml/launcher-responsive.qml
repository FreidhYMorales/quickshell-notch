import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root

    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    property real fullResultsHeight: 0
    property real fullShapeHeight: 0
    property real fullWindowHeight: 0
    property real searchFieldHeight: 0
    property real searchFieldY: 0

    function verifyResults(query, expectedRows, noMatches = false) {
        const results = Visual.findNamed(root.target.content, "launcher-results");
        if (!results) {
            console.error("launcher responsive: results viewport missing");
            return false;
        }
        const row = Visual.findNamed(root.target.content, "launcher-no-matches");
        if (Math.abs(results.height - expectedRows * 43) > 1) {
            console.error("launcher responsive: wrong height for " + query + ": " + results.height);
            return false;
        }
        if (noMatches) {
            if (!row || !row.visible) {
                console.error("launcher responsive: No matches is not visible for " + query);
                return false;
            }
            const rowCenter = row.mapToItem(results, 0, 0).y + row.height / 2;
            if (Math.abs(rowCenter - results.height / 2) > 1) {
                console.error("launcher responsive: No matches is not centered: " + rowCenter + "/" + results.height / 2);
                return false;
            }
        }
        return true;
    }

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
            root.center.store.dispatch({ type: "LauncherQuery", text: ">" });
            fullCommands.start();
        }
    }

    Timer {
        id: fullCommands
        interval: 800

        onTriggered: {
            const results = Visual.findNamed(root.target.content, "launcher-results");
            const shape = Visual.findNamed(root.target.content, "center-notch-shape");
            const field = Visual.findNamed(root.target.content, "launcher-search-field");
            if (!results || !shape || !field || Math.abs(results.height - 5 * 43) > 1) {
                console.error("launcher responsive: six commands should cap at five rows: results=" + (results ? results.height : "missing") + " shape=" + (shape ? shape.height : "missing"));
                return Qt.exit(1);
            }
            root.fullResultsHeight = results.height;
            root.fullShapeHeight = shape.height;
            root.fullWindowHeight = root.target.height;
            root.searchFieldHeight = field.height;
            root.searchFieldY = field.y;
            root.center.store.dispatch({ type: "LauncherQuery", text: ">WALLPAPER" });
            shrinkSample.start();
        }
    }

    Timer {
        id: shrinkSample
        interval: 100

        onTriggered: {
            const results = Visual.findNamed(root.target.content, "launcher-results");
            const shape = Visual.findNamed(root.target.content, "center-notch-shape");
            const field = Visual.findNamed(root.target.content, "launcher-search-field");
            const targetShapeHeight = root.fullShapeHeight - root.fullResultsHeight + 43;
            if (!results || !shape || !field || results.height <= 43 || results.height >= root.fullResultsHeight || shape.height <= targetShapeHeight || shape.height >= root.fullShapeHeight || Math.abs(root.target.height - root.fullWindowHeight) > 1) {
                console.error("launcher responsive: shrink is not in progress together: results=" + (results ? results.height : "missing") + " shape=" + (shape ? shape.height : "missing") + " window=" + root.target.height + "/" + root.fullWindowHeight);
                return Qt.exit(1);
            }
            const contentShrink = root.fullResultsHeight - results.height;
            const shapeShrink = root.fullShapeHeight - shape.height;
            const fieldY = field.y;
            if (Math.abs(contentShrink - shapeShrink) > 1 || field.height !== root.searchFieldHeight || Math.abs(fieldY - root.searchFieldY) > 0.5) {
                console.error("launcher responsive: the fixed search row and result viewport are not morphing with the notch: content=" + contentShrink + " shape=" + shapeShrink);
                return Qt.exit(1);
            }
            settledShrink.start();
        }
    }

    Timer {
        id: settledShrink
        interval: 330

        onTriggered: {
            const shape = Visual.findNamed(root.target.content, "center-notch-shape");
            const targetHeight = root.fullShapeHeight - root.fullResultsHeight + 43;
            if (!root.verifyResults(">WALLPAPER", 1) || !shape || Math.abs(shape.height - targetHeight) > 1 || Math.abs(root.target.height - root.fullWindowHeight) > 1) {
                console.error("launcher responsive: five-to-one contraction did not settle cleanly");
                return Qt.exit(1);
            }
            root.center.store.dispatch({ type: "LauncherQuery", text: ">" });
            growSample.start();
        }
    }

    Timer {
        id: growSample
        interval: 350

        onTriggered: {
            const results = Visual.findNamed(root.target.content, "launcher-results");
            const shape = Visual.findNamed(root.target.content, "center-notch-shape");
            const field = Visual.findNamed(root.target.content, "launcher-search-field");
            if (!results || !shape || !field || Math.abs(results.height - root.fullResultsHeight) > 1 || Math.abs(shape.height - root.fullShapeHeight) > 1 || field.height !== root.searchFieldHeight || Math.abs(field.y - root.searchFieldY) > 0.5) {
                console.error("launcher responsive: retargeted growth did not reach its target while keeping the search row fixed: results=" + (results ? results.height : "missing") + "/" + root.fullResultsHeight + " shape=" + (shape ? shape.height : "missing") + "/" + root.fullShapeHeight + " field=" + (field ? field.y : "missing") + "/" + root.searchFieldY);
                return Qt.exit(1);
            }
            root.center.store.dispatch({ type: "LauncherQuery", text: ">THE" });
            oneCommand.start();
        }
    }

    Timer {
        id: oneCommand
        interval: 700

        onTriggered: {
            if (!root.verifyResults(">THE", 1)) {
                return Qt.exit(1);
            }
            if (Math.abs(root.target.size.height - root.fullShapeHeight + root.fullResultsHeight - 43) > 1) {
                console.error("launcher responsive: notch did not settle to one row");
                return Qt.exit(1);
            }
            root.center.store.dispatch({ type: "LauncherQuery", text: ">no-such-command-xyz" });
            noCommands.start();
        }
    }

    Timer {
        id: noCommands
        interval: 700

        onTriggered: {
            if (!root.verifyResults(">no-such-command-xyz", 1, true))
                return Qt.exit(1);
            root.center.store.dispatch({ type: "LauncherQuery", text: "no-such-app-xyz" });
            noApps.start();
        }
    }

    Timer {
        id: noApps
        interval: 700

        onTriggered: {
            if (!root.verifyResults("no-such-app-xyz", 1, true))
                return Qt.exit(1);
            console.log("launcher responsive: capped, content-sized, and centered empty states");
            Qt.exit(0);
        }
    }
}

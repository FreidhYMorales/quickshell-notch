import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 400; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: false });
        }
    }
    TestCase { name: "ControlCenterDfGating"; when: root.target !== null
        function test_df_runs_only_while_open() {
            wait(300);
            root.target.open = true;
            wait(400);
            if (!Visual.findText(root.target.content, "25%")) { console.error("resource summary: df sample is missing"); return Qt.exit(1); }
            root.target.open = false;
            wait(2200);
            Qt.exit(0);
        }
    }
}

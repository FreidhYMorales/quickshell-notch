import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the control center under smoke and checks the two new tiles: the
// caffeine tile is shown off and lights when enabled, and the profile tile is
// hidden while no backend has answered.
ShellRoot {
    id: root

    property var target: null
    property var offColor: null
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var caffeine: Services.Caffeine }', root)

    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            root.target = component.createObject(null, {
                screen: Quickshell.screens[0],
                open: true
            });
            first.start();
        }
    }

    Timer {
        id: first

        interval: 500
        onTriggered: {
            const caffeine = Visual.findText(root.target.content, "󰅶");
            if (!caffeine) {
                console.error("cc tiles: caffeine tile missing");
                return Qt.exit(1);
            }
            const profiles = ["󰓅", "󰚀", "󰌪"];
            for (let i = 0; i < profiles.length; i++) {
                if (Visual.findText(root.target.content, profiles[i])) {
                    console.error("cc tiles: profile tile shown without a backend");
                    return Qt.exit(1);
                }
            }
            root.offColor = caffeine.color;
            root.services.caffeine.enabled = true;
            second.start();
        }
    }

    Timer {
        id: second

        interval: 300
        onTriggered: {
            const caffeine = Visual.findText(root.target.content, "󰅶");
            if (!caffeine || String(caffeine.color) === String(root.offColor)) {
                console.error("cc tiles: caffeine tile did not light");
                return Qt.exit(1);
            }
            console.log("cc tiles: caffeine off, profile hidden, caffeine lit");
            Qt.exit(0);
        }
    }
}

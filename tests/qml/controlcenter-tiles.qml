import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the control center under smoke and drives the two new tiles: clicking
// the caffeine tile lights it and enables the service, and the profile tile
// appears with the active profile's glyph and lit state once the backend has
// answered.
ShellRoot {
    id: root

    property var target: null
    property var offColor: null
    property var litColor: null
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var caffeine: Services.Caffeine; property var powerProfile: Services.PowerProfile }', root)

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
            caffeine.parent.toggled();
            second.start();
        }
    }

    Timer {
        id: second

        interval: 300
        onTriggered: {
            if (root.services.caffeine.enabled !== true) {
                console.error("cc tiles: click did not toggle caffeine");
                return Qt.exit(1);
            }
            const caffeine = Visual.findText(root.target.content, "󰅶");
            if (!caffeine || String(caffeine.color) === String(root.offColor)) {
                console.error("cc tiles: caffeine tile did not light");
                return Qt.exit(1);
            }
            root.litColor = caffeine.color;
            root.services.powerProfile.current = "power-saver";
            third.start();
        }
    }

    Timer {
        id: third

        interval: 300
        onTriggered: {
            const leaf = Visual.findText(root.target.content, "󰌪");
            if (!leaf) {
                console.error("cc tiles: profile tile missing after the backend answered");
                return Qt.exit(1);
            }
            if (String(leaf.color) !== String(root.litColor)) {
                console.error("cc tiles: profile tile is not lit for power-saver");
                return Qt.exit(1);
            }
            console.log("cc tiles: caffeine click lights the tile, profile glyph follows the backend");
            Qt.exit(0);
        }
    }
}

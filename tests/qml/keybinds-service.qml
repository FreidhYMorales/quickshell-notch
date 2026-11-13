import QtQuick
import Quickshell

// Reads the Keybinds service against a fake `hyprctl` on PATH: the registry
// rows when it works, the unavailable flag when the read fails.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var keybinds: Services.Keybinds }', root)
    readonly property bool failing: Quickshell.env("NOTCH_FAKE_KEYBINDS") === "fail"

    Timer {
        interval: 600
        running: true
        onTriggered: {
            root.services.keybinds.refresh();
            check.start();
        }
    }

    Timer {
        id: check

        interval: 1200
        onTriggered: {
            const keybinds = root.services.keybinds;
            if (root.failing) {
                if (keybinds.available !== false || keybinds.rows.length !== 0) {
                    console.error("keybinds service: a broken registry still reports rows");
                    return Qt.exit(1);
                }
                console.log("keybinds service: reports unavailable");
                return Qt.exit(0);
            }
            if (keybinds.available !== true) {
                console.error("keybinds service: registry not read");
                return Qt.exit(1);
            }
            const rows = keybinds.rows;
            if (rows.length !== 2 || rows[0].keys !== "Super + RETURN" || rows[0].description !== "Open Terminal" || rows[1].keys !== "Ctrl + Alt + F") {
                console.error("keybinds service: unexpected rows " + JSON.stringify(rows));
                return Qt.exit(1);
            }
            console.log("keybinds service: rows from the registry");
            Qt.exit(0);
        }
    }
}

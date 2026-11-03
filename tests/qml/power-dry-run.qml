import QtQuick
import Quickshell

// Runs every power action through the Power service and exits; the runner
// checks the log and that no fake binary was called.
ShellRoot {
    id: root

    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var power: Services.Power }', root)

    Timer {
        interval: 300
        running: true
        onTriggered: {
            const actions = ["lock", "suspend", "logout", "reboot", "poweroff"];
            for (let i = 0; i < actions.length; i++)
                root.services.power.run(actions[i]);
            done.start();
        }
    }

    Timer {
        id: done

        interval: 1000
        onTriggered: Qt.exit(0)
    }
}

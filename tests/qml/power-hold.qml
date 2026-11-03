import QtQuick
import Quickshell

// Drives the centre store like the power menu keys would: a hold released
// early, then a full hold with a key auto-repeat start in the middle.
ShellRoot {
    id: root

    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    readonly property string monitor: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    property int step: 0

    function send(event) {
        root.center.store.dispatch(event);
    }

    // [delay before the step, what it does]
    readonly property var script: [[300, () => {
                send({ type: "PowerOpen", monitor: root.monitor, action: "reboot" });
                send({ type: "HoldStart", action: "reboot" });
            }], [500, () => send({ type: "HoldCancel" })], [1500, () => {
                console.log("probe: cancel phase done");
                send({ type: "PowerMove", step: 1 });
                send({ type: "HoldStart", action: "poweroff" });
            }], [600, () => send({ type: "HoldStart", action: "poweroff" })], [700, () => console.log("probe: complete phase checked")], [100, () => Qt.exit(0)]]

    Timer {
        id: tick

        interval: root.script[0][0]
        running: root.monitor !== ""
        onTriggered: {
            root.script[root.step][1]();
            root.step++;
            if (root.step < root.script.length) {
                interval = root.script[root.step][0];
                start();
            }
        }
    }
}

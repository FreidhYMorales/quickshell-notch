import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root

    property var target: null
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var caffeine: Services.Caffeine }', root)

    Timer {
        interval: 600
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) {
                console.error("controlcenter keyboard: component status " + component.status + ", screens " + Quickshell.screens.length + ", " + component.errorString());
                return Qt.exit(2);
            }
            root.target = component.createObject(null, {
                screen: Quickshell.screens[0],
                open: true,
                keyboardMode: true
            });
        }
    }

    TestCase {
        name: "ControlCenterKeyboard"
        when: root.target !== null

        function test_navigation_and_activation() {
            const scope = Visual.findNamed(root.target.content, "cc-keyboard-scope");
            scope.focusFirst();
            wait(100);
            const lock = Visual.findNamed(root.target.content, "cc-power-lock");
            const suspend = Visual.findNamed(root.target.content, "cc-power-suspend");
            const caffeine = Visual.findNamed(root.target.content, "cc-control-tile-󰅶");
            tryVerify(() => lock.activeFocus, 1000);
            verify(lock.activeFocus, "the selected action can receive keyboard focus");
            verify(lock.scale > 1, "keyboard focus grows the selected control");

            keyClick(Qt.Key_Tab);
            tryVerify(() => suspend && suspend.activeFocus, 1000);
            keyClick(Qt.Key_Tab, Qt.ShiftModifier);
            tryVerify(() => lock.activeFocus, 1000);

            verify(caffeine, "caffeine tile is present");
            caffeine.forceActiveFocus();
            keyClick(Qt.Key_Space);
            tryVerify(() => root.services.caffeine.enabled, 1000);

            root.target.view = "notifications";
            scope.focusFirst();
            keyClick(Qt.Key_Escape);
            tryVerify(() => root.target.view === "root" && root.target.open, 1000);

            keyClick(Qt.Key_Escape);
            tryVerify(() => !root.target.open, 1000);
            console.log("controlcenter keyboard: Tab focus, Space activation and Escape close");
            Qt.exit(0);
        }
    }
}

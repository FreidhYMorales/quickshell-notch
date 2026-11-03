import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root

    property var surface: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    function named(items, name) {
        for (const item of items) {
            if (item.visible && item.objectName === name)
                return item;
            const children = item.children;
            const found = children && typeof children.length === "number" ? named(children, name) : null;
            if (found)
                return found;
        }
        return null;
    }

    TestCase {
        name: "PolkitLayout"
        when: true

        function test_layout() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "PolkitRequest",
                flowId: {
                    message: "Authentication is needed to run `/usr/bin/true' as the super user",
                    isResponseRequired: true
                },
                monitor: screen.name
            });
            wait(700);

            const background = root.named(root.surface.content, "polkitBackground");
            const message = root.named(root.surface.content, "polkitMessage");
            const field = root.named(root.surface.content, "polkitField");
            const button = Visual.findNamed(root.surface.content, "polkitAcceptButton");
            if (!background || !message || !field || !button) {
                console.error("polkit layout: prompt parts missing");
                return Qt.exit(1);
            }
            if (field.height < 24 || field.radius <= 0 || field.color.a === 0) {
                console.error("polkit layout: input is not in a visible capsule");
                return Qt.exit(1);
            }
            if (message.mapToItem(root.surface.content, 0, 0).y < 12) {
                console.error("polkit layout: message has no top padding");
                return Qt.exit(1);
            }
            if (button.mapToItem(root.surface.content, 0, 0).y + button.height > root.surface.content.height) {
                console.error("polkit layout: controls fall outside the notch");
                return Qt.exit(1);
            }
            if (message.contentWidth > message.width) {
                console.error("polkit layout: message is clipped");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}

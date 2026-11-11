import QtQuick
import QtQuick.Window

Window {
    id: root
    property var surface
    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        surface = component.createObject(null, {
            demo: false,
            users: [
                {
                    name: "alice",
                    displayName: "Alice"
                },
                {
                    name: "bob",
                    displayName: "Bob"
                }
            ],
            username: "alice"
        });
        if (!surface) {
            Qt.exit(2);
            return;
        }
        surface.showLogin();
        const avatar = surface.accountAvatar;
        if (!avatar || avatar.width !== 116 || avatar.height !== 116) {
            Qt.exit(3);
            return;
        }
        if (surface.avatarSource().toString() !== "file:///var/lib/AccountsService/icons/alice") {
            Qt.exit(6);
            return;
        }
        surface.chooseAccount("bob");
        if (surface.username !== "bob" || surface.displayName() !== "Bob") {
            Qt.exit(4);
            return;
        }
        surface.stateName = "authenticating";
        surface.chooseAccount("alice");
        if (surface.username !== "bob") {
            Qt.exit(5);
            return;
        }
        Qt.exit(42);
    }
}

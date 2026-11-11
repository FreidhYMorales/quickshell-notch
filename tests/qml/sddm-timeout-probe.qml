import QtQuick
import QtQuick.Window

Window {
    id: testWindow
    width: 1280
    height: 720
    visible: true
    property var config: ({})
    property var userModel: ({ count: 0, lastIndex: 0 })
    property var sessionModel: []
    property QtObject sddm: QtObject {
        signal loginFailed()
        signal loginSucceeded()
        function login(user, password, session) {}
    }
    function findItem(item, name) {
        if (item.objectName === name)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = findItem(item.children[i], name);
            if (found)
                return found;
        }
        return null;
    }

    Loader {
        id: loader
        source: "../../sddm/notch/Main.qml"
        onStatusChanged: {
            if (status === Loader.Error)
                Qt.exit(2);
        }
    }

    Timer {
        id: probe
        interval: 250
        running: true
        onTriggered: {
            if (loader.status !== Loader.Ready) {
                console.error("theme did not load");
                Qt.exit(2);
                return;
            }
            const theme = loader.item;
            theme.view = "login";
            theme.authenticating = true;
            theme.exiting = true;
            theme.reveal = 0;
            theme.authenticationDelayed();
            if (!theme.authenticating || theme.exiting || theme.errorMessage !== "Authentication still in progress") {
                console.error("timeout did not preserve pending attempt");
                Qt.exit(3);
                return;
            }
            const field = testWindow.findItem(theme, "sddmPassword");
            if (!field || field.enabled) {
                console.error("password field remained enabled");
                Qt.exit(7);
                return;
            }
            field.text = "test value";
            theme.submit();
            if (!theme.authenticating || theme.exiting) {
                console.error("pending attempt allowed another submit");
                Qt.exit(4);
                return;
            }
            testWindow.sddm.loginSucceeded();
            if (theme.authenticating || !theme.exiting || theme.reveal !== 0) {
                console.error("late success did not restore notch frame");
                Qt.exit(5);
                return;
            }
            theme.authenticating = true;
            theme.exiting = false;
            theme.authenticationDelayed();
            testWindow.sddm.loginFailed();
            if (theme.authenticating || !theme.passwordError || theme.errorMessage !== "Incorrect password") {
                console.error("late failure did not begin error feedback");
                Qt.exit(6);
                return;
            }
            console.log("SDDM timeout probe passed");
            Qt.exit(42);
        }
    }
}

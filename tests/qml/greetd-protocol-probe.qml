import QtQuick
import Quickshell
import Quickshell.Services.Greetd

// Uses only a private simulated socket supplied by the test runner.
ShellRoot {
    id: root
    property bool sawInfo: false
    property bool sawRecoverableError: false
    property bool sawPrompt: false
    readonly property bool failureTest: Quickshell.env("NOTCH_GREETD_TEST_FAILURE") === "1"

    Component.onCompleted: {
        if (!Greetd.available) {
            console.error("fake greetd socket unavailable");
            Qt.exit(2);
            return;
        }
        Greetd.createSession("preview-user");
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (message === "Testing" && !error && !responseRequired)
                root.sawInfo = true;
            else if (message === "Recoverable notice" && error && !responseRequired)
                root.sawRecoverableError = true;
            else if (message === "Dummy password:" && responseRequired && !echoResponse) {
                root.sawPrompt = true;
                Greetd.respond("fake-test-secret");
            } else {
                console.error("unexpected authentication message");
                Qt.exit(3);
            }
        }
        function onAuthFailure(message) {
            if (root.failureTest && root.sawPrompt) {
                console.log("greetd final failure probe passed");
                Qt.quit();
                return;
            }
            console.error("unexpected authentication failure: " + message);
            Qt.exit(4);
        }
        function onReadyToLaunch() {
            if (!root.sawInfo || !root.sawRecoverableError || !root.sawPrompt) {
                console.error("missing authentication messages");
                Qt.exit(5);
                return;
            }
            animationDelay.start();
        }
        function onLaunched() {
            console.log("greetd protocol probe passed");
            Qt.quit();
        }
        function onError(error) {
            console.error("greetd protocol error: " + error);
            Qt.exit(6);
        }
    }
    Timer {
        id: animationDelay
        interval: 520
        onTriggered: Greetd.launch(["mock-session-not-executed"], [], false)
    }
}

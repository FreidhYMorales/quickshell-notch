import QtQuick
import Quickshell
import Quickshell.Services.Greetd

// Development fixture only. It refuses the system greetd socket, uses a
// fixed dummy identity/secret and requests only a mock session command.
ShellRoot {
    id: root
    property var preview: null
    readonly property bool autoTest: Quickshell.env("NOTCH_GREETD_AUTOTEST") === "1"
    readonly property bool failureTest: Quickshell.env("NOTCH_GREETD_TEST_FAILURE") === "1"
    readonly property bool retryTest: Quickshell.env("NOTCH_GREETD_RETRY") === "1"
    property int attempts: 0
    property string pendingPassword: ""
    readonly property string socketPath: Quickshell.env("GREETD_SOCK")
    readonly property bool socketAllowed: Quickshell.env("NOTCH_GREETD_MOCK") === "1" && /^\/tmp\/notch-greetd-[A-Za-z0-9]+\/socket$/.test(socketPath)
    readonly property string previewBackground: Quickshell.env("NOTCH_GREETD_PREVIEW_BG")
    readonly property string previewAccent: Quickshell.env("NOTCH_GREETD_PREVIEW_ACCENT")
    readonly property string previewForeground: Quickshell.env("NOTCH_GREETD_PREVIEW_FOREGROUND")
    readonly property string previewWidth: Quickshell.env("NOTCH_GREETD_PREVIEW_WIDTH")

    Component.onCompleted: {
        if (!socketAllowed || !Greetd.available) {
            console.error("refusing anything except a private mock greetd socket");
            Qt.callLater(() => Qt.exit(2));
            return;
        }
        const component = Qt.createComponent("greetd/preview/Main.qml");
        if (component.status !== Component.Ready) {
            console.error(component.errorString());
            Qt.callLater(() => Qt.exit(3));
            return;
        }
        const properties = {
            protocolBackend: backend
        };
        if (previewBackground)
            properties.background = previewBackground;
        if (/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(previewAccent))
            properties.accent = previewAccent;
        if (/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(previewForeground))
            properties.foreground = previewForeground;
        const width = Number(previewWidth);
        if (isFinite(width) && width > 0)
            properties.notchWidth = width;
        preview = component.createObject(null, properties);
        if (!preview) {
            console.error("could not create preview");
            Qt.callLater(() => Qt.exit(4));
            return;
        }
        if (autoTest)
            beginTest.start();
    }
    QtObject {
        id: backend
        function begin(user, password) {
            if (Greetd.state !== GreetdState.Inactive) {
                console.error("mock authentication is already active");
                Qt.exit(5);
                return;
            }
            root.attempts++;
            root.pendingPassword = password;
            Greetd.createSession(user);
        }
        function respond(text) {
            Greetd.respond(text);
        }
    }
    Connections {
        target: root.socketAllowed ? Greetd : null
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                if (echoResponse) {
                    console.error("unexpected visible mock prompt");
                    Qt.exit(6);
                    return;
                }
                Greetd.respond(root.pendingPassword);
            }
            // Informational and recoverable errors do not finish authentication.
        }
        function onAuthFailure(message) {
            root.pendingPassword = "";
            root.preview.completeAuthentication(true);
        }
        function onReadyToLaunch() {
            root.pendingPassword = "";
            root.preview.completeAuthentication(false);
        }
        function onLaunched() {
            if (root.autoTest) {
                console.log(root.retryTest ? "visual greetd retry passed" : "visual greetd success passed");
                Qt.quit();
            } else {
                exitAfterDemo.start();
            }
        }
        function onError(error) {
            console.error("mock greetd error: " + error);
            Qt.exit(7);
        }
    }
    Connections {
        target: root.preview
        function onProtocolAnimationComplete() {
            Greetd.launch(["mock-session-not-executed"], [], false);
        }
        function onProtocolFailureComplete() {
            if (root.retryTest && root.attempts === 1) {
                retryTimer.start();
                return;
            }
            if (root.autoTest) {
                console.log("visual greetd failure passed");
                Qt.quit();
            }
        }
    }
    Timer {
        id: beginTest
        interval: 50
        onTriggered: root.preview.submitDemo(root.failureTest)
    }
    Timer {
        id: retryTimer
        interval: 50
        onTriggered: root.preview.submitDemo(false)
    }
    Timer {
        id: exitAfterDemo
        interval: 1000
        onTriggered: Qt.quit()
    }
}

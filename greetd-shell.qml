import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import "./shell/logic/users.mjs" as Users

// Real greetd greeter. greetd starts it with GREETD_SOCK pointing at its
// socket; without that socket it refuses to run. Accounts come from
// /etc/passwd, which the greeter user can read before any login.
ShellRoot {
    id: root
    property var preview: null
    property var users: []
    property string pendingPassword: ""
    readonly property bool autoTest: Quickshell.env("NOTCH_GREETD_AUTOTEST") === "1"
    readonly property bool failureTest: Quickshell.env("NOTCH_GREETD_TEST_FAILURE") === "1"
    // Test-only credentials. The fixed pair drives the fake-socket tests; the
    // headless PAM test supplies a throwaway account through the environment.
    readonly property string testUser: Quickshell.env("NOTCH_GREETD_TEST_USER") || (failureTest ? "preview-failure" : "preview-user")
    readonly property string testSecret: Quickshell.env("NOTCH_GREETD_TEST_SECRET") || "fake-test-secret"
    readonly property string socketPath: Quickshell.env("GREETD_SOCK")
    // Only a test overrides the session command; greetd executes it as the user.
    readonly property var sessionCommand: {
        const override = Quickshell.env("NOTCH_GREETD_TEST_SESSION");
        return override ? override.split(" ") : ["Hyprland"];
    }
    readonly property string previewBackground: Quickshell.env("NOTCH_GREETD_PREVIEW_BG")
    readonly property string previewAccent: Quickshell.env("NOTCH_GREETD_PREVIEW_ACCENT")
    readonly property string previewForeground: Quickshell.env("NOTCH_GREETD_PREVIEW_FOREGROUND")
    readonly property string previewWidth: Quickshell.env("NOTCH_GREETD_PREVIEW_WIDTH")

    Component.onCompleted: {
        if (!socketPath || !Greetd.available) {
            console.error("greetd socket is unavailable; refusing to start a login surface");
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
            demo: false,
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
            console.error("could not create the login surface");
            Qt.callLater(() => Qt.exit(4));
            return;
        }
        applyUsers();
        if (autoTest)
            beginTest.start();
    }

    function applyUsers() {
        users = Users.humanUsers(passwd.text());
        if (!preview)
            return;
        preview.users = users;
        if (preview.username === "")
            preview.username = Users.defaultUser(users, "");
    }

    FileView {
        id: passwd
        path: "/etc/passwd"
        blockLoading: true
        printErrors: false
        onLoaded: root.applyUsers()
        onLoadFailed: root.users = []
    }
    QtObject {
        id: backend
        function begin(user, password) {
            if (Greetd.state !== GreetdState.Inactive) {
                console.error("authentication is already in progress");
                return;
            }
            if (!user || !password)
                return;
            root.pendingPassword = password;
            root.preview.username = user;
            root.preview.awaitingPrompt = false;
            Greetd.createSession(user);
        }
        function respond(text) {
            Greetd.respond(text);
        }
    }
    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                if (echoResponse) {
                    // PAM wants typed text other than the password.
                    root.preview.awaitingPrompt = true;
                    root.preview.protocolMessage = message;
                    return;
                }
                Greetd.respond(root.pendingPassword);
                return;
            }
            if (message)
                root.preview.protocolMessage = message;
        }
        function onAuthFailure(message) {
            root.pendingPassword = "";
            root.preview.awaitingPrompt = false;
            root.preview.failureText = message || "";
            root.preview.completeAuthentication(true);
        }
        function onReadyToLaunch() {
            root.pendingPassword = "";
            root.preview.awaitingPrompt = false;
            root.preview.completeAuthentication(false);
        }
        function onLaunched() {
            if (root.autoTest)
                console.log("real greeter launch passed");
            // greetd starts the session only after its greeter exits.
            Qt.quit();
        }
        function onError(message) {
            root.pendingPassword = "";
            console.error("greetd error: " + message);
            if (root.preview && root.preview.stateName === "authenticating") {
                root.preview.failureText = message;
                root.preview.completeAuthentication(true);
            }
        }
    }
    Connections {
        target: root.preview
        function onProtocolAnimationComplete() {
            Greetd.launch(root.sessionCommand, [], true);
        }
        function onProtocolFailureComplete() {
            if (root.autoTest) {
                console.log("real greeter failure passed");
                Qt.quit();
            }
        }
    }
    Timer {
        id: beginTest
        interval: 50
        onTriggered: root.preview.submit(root.testUser, root.testSecret)
    }
}

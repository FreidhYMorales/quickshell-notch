import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import "./shell/logic/users.mjs" as Users
import "./shell/logic/greetdVisual.mjs" as Visual

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
    // Deployment may point to a greeter-readable, administrator-managed
    // directory containing theme.conf.user and wallpaper.txt. No user home is
    // searched implicitly at the login screen.
    readonly property string visualDirectory: Quickshell.env("NOTCH_GREETD_VISUAL_DIR")

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
        const visuals = Visual.manifestSettings(manifestFile.text(), visualDirectory) || Visual.visualSettings(themeFile.text(), wallpaperFile.text(), baseThemeFile.text());
        properties.background = previewBackground || visuals.background;
        properties.accent = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(previewAccent) ? previewAccent : visuals.accent;
        properties.foreground = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(previewForeground) ? previewForeground : visuals.foreground;
        const width = Number(previewWidth);
        properties.notchWidth = isFinite(width) && width > 0 ? width : visuals.notchWidth;
        if (autoTest && Quickshell.env("NOTCH_GREETD_TEST_VISUAL") === "1")
            console.log("greeter visual: " + JSON.stringify(visuals));
        preview = component.createObject(null, properties);
        if (!preview) {
            console.error("could not create the login surface");
            Qt.callLater(() => Qt.exit(4));
            return;
        }
        applyUsers();
        if (autoTest) {
            if (Quickshell.env("NOTCH_GREETD_TEST_GEOMETRY") === "1")
                geometryProbe.start();
            else
                beginTest.start();
        }
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
    FileView {
        id: manifestFile
        path: root.visualDirectory ? root.visualDirectory + "/visual.json" : ""
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: themeFile
        path: root.visualDirectory ? root.visualDirectory + "/theme.conf.user" : ""
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: baseThemeFile
        path: root.visualDirectory ? root.visualDirectory + "/theme.conf" : ""
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: wallpaperFile
        path: root.visualDirectory ? root.visualDirectory + "/wallpaper.txt" : ""
        blockLoading: true
        printErrors: false
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
        function power(action) {
            if (action === "poweroff" || action === "reboot") {
                powerProcess.command = ["systemctl", action];
                powerProcess.running = true;
            }
        }
    }
    Process {
        id: powerProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("greeter power action failed: " + exitCode);
        }
    }
    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                if (echoResponse || root.pendingPassword === "") {
                    // Additional PAM prompts must be answered by the user;
                    // never reuse the password for a subsequent secret prompt.
                    root.preview.promptSecret = !echoResponse;
                    root.preview.protocolMessage = message;
                    root.preview.awaitingPrompt = true;
                    return;
                }
                Greetd.respond(root.pendingPassword);
                root.pendingPassword = "";
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
        id: geometryProbe
        interval: Quickshell.env("NOTCH_GREETD_TEST_GEOMETRY_DELAY") === "3000" ? 3000 : 500
        onTriggered: {
            if (!root.preview || !root.preview.screen) {
                console.error("greeter geometry: screen unavailable");
                Qt.exit(8);
                return;
            }
            console.log("greeter geometry: window=" + root.preview.width + "x" + root.preview.height + " output=" + root.preview.screen.width + "x" + root.preview.screen.height);
            beginTest.start();
        }
    }
    Timer {
        id: beginTest
        interval: 50
        onTriggered: root.preview.submit(root.testUser, root.testSecret)
    }
}

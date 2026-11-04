import QtQuick
import Quickshell
import Quickshell.Services.Pam
import "../config"

// Lock screen authentication, without any UI: the typed password goes to a
// fresh PAM conversation per attempt. Tests point configDirectory at a
// throwaway PAM directory instead of /etc/pam.d.
Scope {
    id: root

    property string configDirectory: "/etc/pam.d"
    property string passwordConfig: "quickshell-password"
    property string fingerprintConfig: "quickshell-fprint"
    property bool fingerprintEnabled: false
    property string user: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

    property string pendingPassword: ""
    // Last failed attempt, shown by the lock UI; cleared on a new attempt.
    property string error: ""
    // listening | error
    property string fingerprintState: "listening"

    signal unlocked

    function submit(password: string) {
        if (password.length === 0 || passwordPam.active)
            return;
        root.pendingPassword = password;
        root.error = "";
        passwordPam.start();
    }

    // Ends any running conversation once the session is unlocked, so the
    // fingerprint reader is released.
    function stop() {
        fingerprintRetry.stop();
        if (fingerprintPam.active)
            fingerprintPam.abort();
        if (passwordPam.active)
            passwordPam.abort();
        root.pendingPassword = "";
        root.error = "";
    }

    // Starts the fingerprint listener when enabled; it runs beside the
    // password, and whichever succeeds first unlocks.
    function listen() {
        if (root.fingerprintEnabled && !fingerprintPam.active)
            fingerprintPam.start();
    }

    PamContext {
        id: fingerprintPam

        configDirectory: root.configDirectory
        config: root.fingerprintConfig
        user: root.user

        onResponseRequiredChanged: {
            if (responseRequired)
                respond("");
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked();
            } else {
                root.fingerprintState = "error";
                fingerprintRetry.restart();
            }
        }
    }

    // A fresh conversation per scan; start() returns false while fprintd still
    // holds the previous claim, so keep retrying until it starts.
    Timer {
        id: fingerprintRetry

        interval: Timings.lockFingerprintRetry
        onTriggered: {
            if (!root.fingerprintEnabled)
                return;
            root.fingerprintState = "listening";
            if (!fingerprintPam.start())
                restart();
        }
    }

    PamContext {
        id: passwordPam

        configDirectory: root.configDirectory
        config: root.passwordConfig
        user: root.user

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success)
                root.unlocked();
            else
                root.error = Strings.lockLoginFailed;
        }
    }
}

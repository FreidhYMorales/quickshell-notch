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

    signal unlocked

    function submit(password: string) {
        if (password.length === 0 || passwordPam.active)
            return;
        root.pendingPassword = password;
        root.error = "";
        passwordPam.start();
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

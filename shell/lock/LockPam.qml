import QtQuick
import Quickshell
import Quickshell.Services.Pam

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

    signal unlocked

    function submit(password: string) {
        if (password.length === 0 || passwordPam.active)
            return;
        root.pendingPassword = password;
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
        }
    }
}

pragma Singleton

import Quickshell

// Every user-visible text lives here.
Singleton {
    readonly property string workspaces: "Workspaces"
    readonly property string brightness: "Brightness"
    readonly property string volume: "Volume"
    readonly property string controlCenter: "Control center"
    readonly property string center: "Notch"
}

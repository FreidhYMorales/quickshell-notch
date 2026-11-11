import QtQuick
import QtQuick.Window

// Reads the visual tokens the launcher passes to the preview. The runner
// passes the same `-- notch-preview ...` arguments plus `notch-expect <mode>`.
Window {
    id: root
    visible: false
    property var preview: null
    readonly property var args: Qt.application.arguments
    readonly property int expectAt: args.indexOf("notch-expect")
    readonly property string mode: expectAt >= 0 ? args[expectAt + 1] : ""

    Component.onCompleted: {
        const component = Qt.createComponent("../../greetd/preview/Main.qml");
        if (component.status !== Component.Ready) {
            console.error(component.errorString());
            Qt.exit(2);
            return;
        }
        preview = component.createObject(null);
        if (!preview) {
            Qt.exit(3);
            return;
        }
        check.start();
    }

    Timer {
        id: check
        interval: 50
        onTriggered: {
            root.preview.reveal = 0;
            if (root.preview.morphWidth !== root.preview.notchWidth || root.preview.morphHeight !== 32 || root.preview.notchHeight !== 32 || root.preview.earRadius !== 12 || root.preview.cornerRadius !== 18) {
                Qt.exit(12);
                return;
            }
            if (root.mode === "themed") {
                if (!Qt.colorEqual(root.preview.accent, "#123456")) {
                    Qt.exit(4);
                    return;
                }
                if (!Qt.colorEqual(root.preview.foreground, "#abcdef")) {
                    Qt.exit(5);
                    return;
                }
                if (root.preview.notchWidth !== 420) {
                    Qt.exit(6);
                    return;
                }
                const background = String(root.preview.background);
                if (background.indexOf("my wallpaper.gif") < 0 && background.indexOf("my%20wallpaper.gif") < 0) {
                    Qt.exit(7);
                    return;
                }
            } else {
                if (!Qt.colorEqual(root.preview.accent, "#c6c6c6")) {
                    Qt.exit(8);
                    return;
                }
                if (!Qt.colorEqual(root.preview.foreground, "#e4e4e4")) {
                    Qt.exit(9);
                    return;
                }
                if (root.preview.notchWidth !== 300) {
                    Qt.exit(10);
                    return;
                }
                if (String(root.preview.background) !== "") {
                    Qt.exit(11);
                    return;
                }
            }
            Qt.exit(42);
        }
    }
}

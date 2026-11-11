import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme }', root)
    FileView {
        id: palette
        path: Quickshell.env("NOTCH_GREETD_DATA_DIR") + "/colors.json"
        blockLoading: true
    }
    Component.onCompleted: {
        services.theme.greetdBusy = true;
        services.theme.stageGreetd("/tmp/image.png", palette.path);
        palette.setText('{"colors":{"primary":{"hex":"#654321"},"on_surface":{"hex":"#fedcba"}}}');
        palette.waitForJob();
        const queued = JSON.parse(services.theme.greetdNext.palette);
        console.log("greetd queued palette: " + queued.colors.primary.hex);
        Qt.callLater(() => Qt.quit());
    }
}

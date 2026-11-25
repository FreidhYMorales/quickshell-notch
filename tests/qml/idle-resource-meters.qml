import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root
    function layer(items, name) {
        for (const item of items) {
            if (item.objectName === name)
                return item;
            const nested = item.children && typeof item.children.length === "number" ? layer(item.children, name) : null;
            if (nested)
                return nested;
        }
        return null;
    }
    TestCase {
        name: "IdleResourceMeters"
        when: true
        function test_idle_row_keeps_only_date_and_time() {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const surface = c.createObject(null, { screen: Quickshell.screens[0] });
            wait(200);
            const idle = root.layer(surface.content, "center-idle");
            const row = idle && root.layer([idle], "idle-row");
            if (!row || row.children.length !== 1 || typeof row.children[0].text !== "string" || row.children[0].text.length === 0) {
                console.error("idle row: expected only the date/time text; children:", row ? row.children.length : "missing");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}

pragma Singleton

import Quickshell
import QtQuick

// Visible desktop entries as plain records for the launcher's ranking.
Singleton {
    id: root

    readonly property var list: {
        const out = [];
        const entries = DesktopEntries.applications.values;
        for (let i = 0; i < entries.length; i++) {
            const e = entries[i];
            if (e.noDisplay)
                continue;
            out.push({
                id: e.id,
                name: e.name,
                genericName: e.genericName,
                comment: e.comment,
                keywords: e.keywords,
                icon: e.icon
            });
        }
        return out;
    }

    // Desktop entries load lazily: touch them at startup.
    Component.onCompleted: if (list.length === 0)
        console.warn("Apps: no desktop entries yet")
}

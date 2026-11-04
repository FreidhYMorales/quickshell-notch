pragma Singleton

import Quickshell
import Quickshell.Io
import "../config"

// Session-only caffeine flag: starts off on every launch. The idle inhibitor
// that honours it lives on the always-mapped wallpaper surface.
Singleton {
    id: root

    property bool enabled: false

    function toggle() {
        enabled = !enabled;
    }

    // `qs -c notch ipc call caffeine toggle|on|off`.
    LazyLoader {
        active: !Flags.smoke

        IpcHandler {
            target: "caffeine"

            function toggle(): void {
                root.toggle();
            }

            function on(): void {
                root.enabled = true;
            }

            function off(): void {
                root.enabled = false;
            }
        }
    }
}

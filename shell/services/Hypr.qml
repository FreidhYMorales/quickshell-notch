pragma Singleton

import Quickshell
import "../config"
import "../logic/hyprDsp.mjs" as HyprDsp

// The single wrapper over the compositor: the hl.dsp.* Lua bridge for
// dispatchers and a hl.config eval for the few options the shell owns.
Singleton {
    // Hides or shows the compositor's pointer. A lock surface cannot set a
    // cursor of its own, so the screensaver asks the compositor instead.
    // Never throws. Inert (returns false, no compositor call) under smoke.
    property bool pointerHidden: false

    function setPointerHidden(hidden: bool): bool {
        if (hidden === pointerHidden)
            return true;
        if (Flags.smoke)
            return false;
        const config = hidden ? "hl.config({ cursor = { invisible = true } })" : "hl.config({ cursor = { invisible = false } })";
        try {
            Quickshell.execDetached(["hyprctl", "eval", config]);
            pointerHidden = hidden;
            return true;
        } catch (e) {
            console.warn("Hypr.setPointerHidden: failed", e);
            return false;
        }
    }

    // Returns true when the dispatch was handed to hyprctl, false otherwise.
    // Never throws. Inert (returns false, no compositor call) under smoke.
    function dispatch(name: string, args: var): bool {
        const expr = HyprDsp.dspExpr(name, args ?? []);
        if (expr === null) {
            console.warn("Hypr.dispatch: rejected dispatcher", name);
            return false;
        }
        if (Flags.smoke)
            return false;
        try {
            Quickshell.execDetached(["hyprctl", "dispatch", expr]);
            return true;
        } catch (e) {
            console.warn("Hypr.dispatch: failed", name, e);
            return false;
        }
    }
}

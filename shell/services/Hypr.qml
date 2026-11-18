pragma Singleton

import Quickshell
import "../config"
import "../logic/hyprDsp.mjs" as HyprDsp

// The single wrapper over the compositor: the hl.dsp.* Lua bridge for
// dispatchers and a hl.config eval for the few options the shell owns.
Singleton {
    // Hides or shows the compositor's pointer. A lock surface cannot set a
    // cursor of its own, so the screensaver asks the compositor instead. The
    // call is unconditional: a shell killed while the pointer was hidden
    // leaves the compositor in that state, and only a fresh call undoes it.
    // Never throws. Inert (returns false, no compositor call) under smoke.
    function setPointerHidden(hidden: bool): bool {
        if (Flags.smoke)
            return false;
        const config = hidden ? "hl.config({ cursor = { invisible = true } })" : "hl.config({ cursor = { invisible = false } })";
        try {
            Quickshell.execDetached(["hyprctl", "eval", config]);
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
        return send(expr);
    }

    // Turns the outputs on or off. `hl.dsp.dpms("on")` is a toggle on 0.57:
    // the string is ignored and every call flips the panel, so a wake that
    // follows the compositor's own wake would blacken it again. The table form
    // names the state and is idempotent.
    function setOutputsOn(on: bool): bool {
        const expr = HyprDsp.dpmsExpr(on);
        if (expr === null)
            return false;
        return send(expr);
    }

    function send(expr: string): bool {
        if (Flags.smoke)
            return false;
        try {
            Quickshell.execDetached(["hyprctl", "dispatch", expr]);
            return true;
        } catch (e) {
            console.warn("Hypr.dispatch: failed", expr, e);
            return false;
        }
    }
}

pragma Singleton

import Quickshell
import "../config"
import "../logic/hyprDsp.mjs" as HyprDsp

// The single wrapper over the hl.dsp.* Lua bridge; no other file may call it.
Singleton {
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

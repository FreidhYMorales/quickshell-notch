pragma Singleton

import Quickshell
import "../config"
import "../logic/powerMenu.mjs" as PowerMenu

// Runs the power menu's actions. Under Flags.powerDryRun every action is only
// logged, so tests and smoke runs never lock, suspend or end the session.
Singleton {
    id: root

    function run(action: string): void {
        const command = PowerMenu.commandFor(action);
        if (!command) {
            console.warn("power: unknown action " + action);
            return;
        }
        if (Flags.powerDryRun) {
            console.log("power: dry run " + (command.lock ? "lock" : command.argv.join(" ")));
            return;
        }
        if (command.lock)
            Session.requestLock();
        else
            Quickshell.execDetached(command.argv);
    }
}

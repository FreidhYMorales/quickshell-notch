# Story 14: Hyprland cutover and rollback

## Story

14. As a user, I want Hyprland to start the notch shell with my keybinds remapped and a rollback so that it becomes my daily shell. Requires: #08, #10, #12, #13

## Acceptance criteria

- [ ] Given the cutover has been applied, when Hyprland starts, then the notch shell is the only Quickshell instance running and Super+D opens the control center root, Super+N its notifications subpage, Super+Alt+C toggles the expanded notch on the focused monitor, Super+Space the launcher, Ctrl+Alt+Del the power menu, and the power button locks.
- [ ] Given a fresh clone of my dotfiles, when I deploy it, then `~/.config/quickshell/notch` is the notch shell and `qs -c notch` starts it, with no manual link step.
- [ ] Given the cutover is active, when I run the rollback, then the old bar autostarts with its original keybinds and the notch no longer starts, and at no point do the two shells run together.

## Plan

- Expose the shell: the dotfiles quickshell package moves its old config into a named `default` folder (bare `qs` still runs it) and adds the notch repo as a submodule beside it; the deploy script initialises submodules before stowing, so one clone gives `qs -c notch` on a blank machine, nothing machine-specific is committed, and the dev checkout keeps using `qs -p`.
- Cutover step: stop every running Quickshell instance (old and notch), back up the Hyprland autostart and keybind files, rewrite the autostart to the notch config, rewrite the IPC prefix to `qs -c notch ipc call`, apply the planned remap (Super+D control center root, Super+N notifications, Super+Alt+C expanded, Super+Space launcher, Ctrl+Alt+Del power, power button lock), then start exactly one notch instance.
- Add the two IPC entries the new keys need: control center (open root or the notifications subpage on the focused monitor) and expanded toggle; the routing decisions stay in pure logic with tests, and nothing is registered under smoke.
- Rollback step: restore the backups, stop the notch instance and start the old bar; both directions are idempotent and refuse to finish with two instances running.
- Docs: cutover and rollback steps, the never-run-both rule, and that lock-before-suspend is the shell's own logind inhibitor (no root hook to install or update); the run command after cutover replaces `qs -p` in the development docs.

## Out of scope

- The lock, the idle chain and lock-before-suspend (#30-#32); no root `system-sleep` hook is created or edited.
- Removing the old config from the dotfiles; it stays as the rollback target.
- Turning the notch into its own stow package, or any submodule location other than inside the quickshell package.
- Keybinds beyond the remap: the old shell's dashboard, calendar and notifications-panel keys disappear with it.
- Blank-machine provisioning beyond the dotfiles deploy (packages, drivers, session setup).

## Suggestions (your call)

- The power button already goes through the same `qs ipc call` prefix as the panel keys in the keybind file, so the prefix rewrite covers it without a separate edit.
- One script with `cutover` and `rollback` subcommands sharing a single file list and backup location, the way the dotfiles deploy script already takes package names, so the two directions cannot drift apart.

## Size

normal
Risk: item 3 (new IPC targets and the `qs -c notch` invocation consumed by the Hyprland keybinds), item 5 (edits the live Hyprland autostart/keybinds, the dotfiles deploy and its submodule), item 6 (cutover and rollback are only verifiable by hand)

## Log

- L1 request: /flow-story 14
- L2 decision (user, on the config exposure question): the shell ships as a git submodule inside the dotfiles quickshell stow package, because a blank reinstall must get `qs -c notch` from one clone plus deploy, without a machine-specific link.
- L2 assumptions: the cutover and rollback scripts live in this repo and edit the dotfiles checkout; the user commits and runs them (no sudo needed, since lock-before-suspend no longer uses a root hook); the old shell's `qs ipc call` prefix stays in the rollback backups untouched.
- L3 approval (user): the story is approved as the first integration; the old config is temporary. Once the notch configuration is finished it stays and the old config is discarded, in a later story (rollback exists only for this transition).
- L4 blocker (pair step 1): Quickshell registers `<config dir>/quickshell/shell.qml` as `default` and then ignores every subdirectory (`qs --help`), so a `notch` submodule beside the old config cannot be selected with `qs -c notch`. Either the old config moves into a named `default/` folder in the dotfiles stow package (then bare `qs` still runs it) or the notch is launched by path (`qs -p`) and keybinds use `qs -p ... ipc call`. Decision pending with the user.
- L5 decision (user, pair step 1): move the old config to `default/`. The dotfiles package becomes `.config/quickshell/default/` (old, still run by bare `qs`) plus `.config/quickshell/notch/` (submodule). The dotfiles edits (move, submodule add, deploy submodule init) are done by hand in the dotfiles repo, since this repo's tests cannot own another checkout; the cutover script only edits the Hyprland files and swaps the running instance, and fails cleanly when the deployed notch config is missing.
- L6 correction batch (verifier FAIL #1): `qs kill` selects one instance by config path (`command.cpp` `selectInstance`/`killInstances`), so the script now enumerates `qs list --all` and kills every instance by pid, polls until zero before the swap and exactly one after it, verifies the Hyprland remap and restores the originals on drift, and the keybind requests queue in order (`shell/logic/requestQueue.mjs`). Docs reworded: the dotfiles migration is pending, not done. Commits `27fe05e`..`f34da10`.
- L7 verifier recheck #2: FAIL on one residual defect, reproduced: a cutover that fails on drift still writes the drifted files as the permanent backup, so after fixing the drift and re-running, `rollback` restores the stale drifted line. Secondary notes: a failed verify leaves no shell running, a launch failure leaves the files rewritten, and the instance guard trusts `qs list`. Awaiting the user's decision on a second correction batch.
- L8 second correction batch (user authorised): each cutover snapshots the files into a temp dir, restores from that snapshot on failure, and promotes it to the rollback backup only after `verify_rewrite` passes; `instances_ok` refuses to run when `qs list --all` fails. Commits `9554b2c`..`faf97ed`. Accepted tradeoffs, recorded here: a failed verification leaves no shell running (recover with `qs -d`; `rollback` correctly answers "nothing to roll back"), a launch failure leaves the files rewritten (a `rollback` restores them, verified end to end), and a failing `rm` of the temp dir is theoretical.
- L9 verifier recheck #3: **PASS**. Strict TDD order checked for all 13 test→feat/fix pairs, red reproduced at `9554b2c` and `6526092`, no assertion weakened, full diff matches the story. `make check` exit 0 (`smoke: config loaded`); `node --test tests/cutover.test.mjs` 10/10. Manual/pending: the dotfiles migration (C2) is done by hand in that repo before the first real cutover, and the real reboot plus key presses (C1, item 6) are walked then.
- L10 dotfiles migration applied (corrects the layout in L5): the submodule sits at `.config/quickshell/notch-repo/` and `.config/quickshell/notch` is a committed relative symlink to `notch-repo/shell`. A submodule directly at `notch/` would leave `notch/shell.qml` missing (the entry point is `shell/shell.qml`), and a symlink to the entry file itself fails because its relative imports resolve against the link's directory; a symlink to the directory loads fine (both tried). The old config moved wholesale into `default/` with `git mv`, keeping the untracked `modules/notch` it imports. Dotfiles commits: `9be4dd0` (checkpoint of the pending work) and `9ad43ef` (layout plus `deploy.sh` submodule init). Verified with the real deploy: bare `qs list` resolves `.../quickshell/default/shell.qml` and `qs list -c notch` resolves `.../quickshell/notch/shell.qml`.
- Risk: item 3 (new IPC targets and the `qs -c notch` invocation consumed by the Hyprland keybinds), item 5 (edits the live Hyprland autostart/keybinds, the dotfiles deploy and its submodule), item 6 (cutover and rollback are only verifiable by hand).

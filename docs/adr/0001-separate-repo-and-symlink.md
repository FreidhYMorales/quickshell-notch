# 0001. Separate repo, symlinked into ~/.config/quickshell/notch

- Status: accepted
- Date: 2026-10-21

## Context

The notch shell replaces an existing bar config at `~/.config/quickshell` (default config). The old bar must stay usable as a fallback while the notch is unfinished. The user's dotfiles repo is stow-style.

## Decision

This folder is its own git repo, pushed to GitHub. The runtime config lives in `shell/`, symlinked to `~/.config/quickshell/notch` and run with `qs -c notch`. When stable, the dotfiles repo includes it as a submodule or stow package.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Develop inside the dotfiles repo | One repo | Mixes unstable work with daily config; noisy history | Fallback and history isolation matter more |
| Replace `~/.config/quickshell` directly | No named config | Loses the old bar as fallback | Breaks daily use while unfinished |

## Consequences

- Positive: old bar and notch coexist (`qs` vs `qs -c notch`); edits in the repo are live after a restart.
- Negative: the symlink is a manual setup step; tests and docs must live outside `shell/` so they are not loaded as config.
- Follow-ups: `/flow:bootstrap` creates the repo; later, add it to the dotfiles repo.

## Update 2026-10-21

`~/.config/quickshell` is itself a stow symlink into the dotfiles repo (the old config). Creating `~/.config/quickshell/notch` would place the link inside the dotfiles working tree and the old config folder. Until cutover, the notch runs straight from the repo with `qs -p shell/shell.qml` (no symlink). The final integration (own stow package, submodule, or unfolding the stow link) is decided in the `notch-cutover` phase, together with the `qs -c notch` IPC target names.

## Update 2026-11-05

Cutover decided (story 14). Quickshell registers `<config dir>/quickshell/shell.qml` as `default` and then ignores every subdirectory, so the dotfiles quickshell package now holds:

- `.config/quickshell/default/` — the old bar (its files moved there with `git mv`); bare `qs` still runs it, so its keybinds and the rollback keep working untouched.
- `.config/quickshell/notch/` — this repo as a git submodule, run with `qs -c notch`.

`deploy.sh` initialises submodules before stowing, so a fresh clone plus deploy yields both configs and nothing machine-specific is committed. `scripts/notch-cutover.sh cutover|rollback` edits the Hyprland autostart/keybinds and swaps the running instance, backing up the originals under the notch state dir. The old bar is temporary: once the notch configuration is complete it stays and the old config is removed in a later story.

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

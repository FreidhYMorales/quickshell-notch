# AGENTS.md

Rules for ANY AI (CLI or browser) working on this repo. Keep it short; details live in `docs/architecture.md`.

## Stack

QML + Quickshell 0.3 (Qt 6.12), JavaScript ES modules (`.mjs`) for pure logic, matugen colours. Zero npm dependencies. Product plan: `docs/plans/notch/plan.md`.

## Platforms

- Targets: Arch Linux + Hyprland (Wayland), all monitors; see docs/architecture.md.
- Dev setup: follow `docs/development.md`. Do not assume the maintainer's OS, package manager or shell.

## Folder map

```
shell/                 runtime config (symlinked to ~/.config/quickshell/notch; run `qs -c notch`)
  shell.qml            entry: Variants -> Scope -> PanelWindow per monitor
  config/              tokens: font (once), timings, colours, reserveSpace, Strings
  services/            data singletons (Battery, Audio, Notifs, Mpris, Hypr, SysInfo, ...)
  logic/               PURE .mjs: no Quickshell/Qt imports
  components/          reusable UI (ears, ArcMeter, Slider, ...)
  notches/{center,workspaces,osd,controlcenter}/
tests/                 <name>.test.mjs for shell/logic
docs/                  architecture, development, ADRs, plans
```

## Conventions

- Naming: `PascalCase.qml`; services are `pragma Singleton` + `qmldir` entry; logic `camelCase.mjs`; tests `tests/<name>.test.mjs`.
- Separation: services give data, `logic/` decides, QML paints. No literals for colours, timings, fonts or UI text outside `shell/config/`.
- Format/lint: run `make fmt` and `make lint` before committing (Qt 6 tools in `/usr/lib/qt6/bin`, not `/usr/bin`).
- Commits: conventional commits; no AI attribution, no `Co-Authored-By` lines.
- Tests first (Strict TDD) for `shell/logic/`. Run `make test`; typecheck: n/a. UI is verified manually with `qs -c notch`.
- Work is done only when `make check` passes; never weaken or skip checks to make it pass. (The toolkit Stop hook runs it before an agent may finish.)

## Gotchas (from the old config)

- Add every new QML file to its folder's `qmldir`.
- `.mjs` files imported by QML run on Qt's V4 engine, not Node: no optional catch binding (`catch {`); write `catch (_e)`. Node tests pass either way, so this only fails when Quickshell loads the file.
- Every `PanelWindow` sets `mask: Region { item: ... }`; fixed size, animate inside.
- Hyprland dispatch: use the `hl.dsp.*` Lua bridge; plain `Hyprland.dispatch` does not work on this build.
- Special workspace active state comes from the raw event `activespecial`.
- Mpris: use `players.values` and `playbackStatus`.
- Avoid permanent forking polls; prefer event watchers and `FileView`.
- Services degrade gracefully: missing data -> hide the element + `console.warn`.
- Reuse from `~/Mio/Configuraciones/dotfiles/quickshell/.config/quickshell` per the plan's "Reuse map".

## Do not

- Do not change frozen contracts (n/a: solo project) without explicit agreement.
- Do not add dependencies or tools without approval.
- Do not commit secrets (none exist; there is no `.env`).
- Do not edit files owned by another work package (n/a: solo).
- Do not import Quickshell/Qt in `shell/logic/`.

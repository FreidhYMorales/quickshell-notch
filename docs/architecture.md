# Architecture: Quickshell notch shell

- Status: approved
- Mode: greenfield
- Last updated: 2026-10-21
- ADRs: [docs/adr/](adr/)
- Product plan: [plans/notch/plan.md](plans/notch/plan.md)

## Constraints

| Constraint | Value |
|---|---|
| Deadline | none (personal project) |
| Team | 1 (solo developer) |
| Hosting / budget | n/a: local desktop shell; source on GitHub |
| Required capabilities | Hyprland IPC + Lua dispatch bridge (`hl.dsp.*`; plain `Hyprland.dispatch` does not work on this build), Pipewire, Mpris, notifications server, polkit agent, udev brightness, matugen colours |
| Target platforms | Arch Linux + Hyprland, Wayland only, all monitors (laptop OLED + externals) |
| Distribution | Own git repo on GitHub, included in the dotfiles repo as a submodule at `quickshell/.config/quickshell/notch` and run with `qs -c notch`; the old bar stays beside it as the named config `default` until it is retired ([ADR 0001](adr/0001-separate-repo-and-symlink.md)) |
| Dev environments | Arch Linux only (maintainer's machine); setup in [development.md](development.md) |

Host verified: Quickshell 0.3.2 (AUR `quickshell-git`), Qt 6.12, Node 26, deno 2.9, matugen 4.2.

## Stack

| Layer | Choice | Why (ADR) |
|---|---|---|
| Language | QML + JavaScript ES modules (`.mjs`) | The project exists for Quickshell; no alternatives considered |
| Frontend | Quickshell (`PanelWindow` layer surfaces) | [ADR 0004](adr/0004-layer-surfaces-and-input.md) |
| Backend / data | Quickshell services (Hyprland, Pipewire, Mpris, Notifications, Polkit, UPower) wrapped in singletons | [ADR 0002](adr/0002-hybrid-layout-pure-logic.md) |
| Key libraries | none (zero npm dependencies); matugen for colours | [ADR 0005](adr/0005-visual-tokens.md) |

## Architecture style

Hybrid layered layout ([ADR 0002](adr/0002-hybrid-layout-pure-logic.md)): data (`services/`), decisions (`logic/`, pure `.mjs`) and painting (`components/`, `notches/`) are separate. QML asks `logic/` what to show and paints it. Pure logic keeps the testable surface large without a QML test runner. Rejected as over-engineering: a plugin system, per-feature packages, a C++ module.

```
.
├── shell/                  # source; deployed as ~/.config/quickshell/notch (dotfiles submodule)
│   ├── shell.qml           # entry: Variants over screens -> Scope -> notch surfaces
│   ├── config/             # singleton tokens: Fonts, Timings, Colours, Layout, Strings
│   ├── services/           # data singletons: Battery, Audio, Notifs, Mpris, Hypr, SysInfo, Time, Brightness, ...
│   ├── logic/              # PURE .mjs: state machine, notification queue, workspace symbols, calendar grid, ...
│   ├── components/         # reusable UI: ear shapes (EarCurve.js), ArcMeter, Slider, ...
│   └── notches/
│       ├── center/         # main notch: idle, expanded, toast, launcher, power, polkit
│       ├── workspaces/     # top-left
│       ├── osd/            # volume + brightness
│       └── controlcenter/  # top-right
├── tests/                  # <name>.test.mjs, run with node --test
├── docs/                   # architecture, development, ADRs, plans
├── Makefile                # quality gate (created by /flow:bootstrap)
└── AGENTS.md
```

Every QML folder has its own `qmldir`.

| Folder | What goes here | What must NOT go here |
|---|---|---|
| `shell/config/` | Tokens: font family (defined once), timings, colours, `reserveSpace`, all UI strings | Logic, service calls |
| `shell/services/` | `pragma Singleton` data sources exposing properties and signals; graceful degradation | Layout, colours, display decisions |
| `shell/logic/` | Pure functions / reducers in `.mjs` | Any Quickshell or Qt import, `Qt.*`, timers, I/O |
| `shell/components/` | Reusable visual pieces parameterised by properties | Service access, hardcoded strings/colours |
| `shell/notches/*` | One notch per folder: surface + its views, wiring services -> logic -> components | Business rules that can live in `logic/` |
| `tests/` | `node --test` suites for `shell/logic/` | QML tests |

## Conventions

- Naming: QML components `PascalCase.qml`; services are singletons (`pragma Singleton` + `singleton` line in `qmldir`); logic files `camelCase.mjs`; tests `tests/<name>.test.mjs`; constants in `config/` tokens, never inline literals.
- Imports: QML imports logic with `import "../logic/x.mjs" as X`; tests import the same file.
- Formatter / linter: `qmlformat` + `qmllint` from `/usr/lib/qt6/bin` (NOT `/usr/bin`, which is Qt 5); `deno fmt` + `deno lint` for `.mjs`. Default configs, no config files.
- Commits: conventional commits, no AI attribution or `Co-Authored-By` lines.
- Branching / PR flow: `main` + short feature branches, merged when `make check` is green.
- Dependencies: zero npm dependencies; any new tool or dependency needs user approval.
- Contracts: n/a (solo).

## Testing

([ADR 0003](adr/0003-testing-strategy.md))

| Layer | Tool | What MUST be tested | Command |
|---|---|---|---|
| Unit / domain | `node --test` | Everything in `shell/logic/` (state priorities, notification queue, workspace symbols, calendar grid, ...) | `node --test tests/` |
| Contract | n/a | n/a (no external API; service shapes are internal) | n/a |
| Golden | n/a | n/a | n/a |
| Smoke | `qs` | The config loads without errors | `make smoke` |
| UI | manual | Animations, visuals, hover, input masks | `qs -c notch` |

Strict TDD: write the failing test first for every `logic/` change. `qmltestrunner` is not used (exits 1 silently on the offscreen platform).

## Config & secrets

- No secrets in this project; no `.env` or `.env.example` needed.
- User-tunable settings live in `shell/config/` (e.g. `reserveSpace`, timings).
- `.gitignore`: `.claude/settings.local.json`, `node_modules/`, `.qmlls.ini`.
- CI/deploy secrets: none.

## CI / deploy

- Quality gate: `make check`, created by `/flow:bootstrap` from this recipe (read-only, non-interactive, in order):
  1. Format check:
     - QML: for each `*.qml` under `shell/`: `/usr/lib/qt6/bin/qmlformat "$f" | diff -u "$f" -` (fail on any diff)
     - JS: `deno fmt --check shell/logic tests`
  2. Lint:
     - QML: `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml <all .qml files>` (Quickshell types from `/usr/lib/qt6/qml/Quickshell`)
     - JS: `deno lint shell/logic tests`
  3. Typecheck: n/a (no type system; qmllint covers QML types)
  4. Tests: `node --test tests/`
  5. Smoke: `make smoke` = `timeout 10 qs -p shell/shell.qml` with output captured; fail if the log contains `ERROR` or a load error (exit code 124 from timeout is the expected success path).
- Make targets: `check`, `fmt` (writes: `qmlformat -i`, `deno fmt`), `fmt-check`, `lint`, `test`, `smoke`.
- CI (GitHub Actions) on push and PR: `node --test tests/`, `deno fmt --check` + `deno lint`, qmlformat check. qmllint with Quickshell types and the smoke test run only locally (they would need `quickshell-git` built and a Wayland session).
- Deploy target: local only. The dotfiles submodule pins a commit; `main` becomes live after a `git submodule update --remote` and a notch restart.

## Observability & errors

- One `LoggingCategory` per area: `notch.services`, `notch.notches`, `notch.logic` (logic itself stays pure; callers log).
- Services degrade gracefully: unavailable data (no battery, no player, no Pipewire node) -> hide the element + `console.warn` once; never show broken UI.
- Debugging: run `qs -c notch` in a terminal and read the log.

## Accessibility & i18n

- UI text in English, centralised in `shell/config/` `Strings`; following the system locale is a far-future idea.
- Keyboard navigation for launcher and power menu: arrows/hjkl, Enter, Esc. Exclusive keyboard focus only while launcher/power/polkit is open.
- Contrast: dark-scheme `on_surface` on pure black; muted variant only for secondary text.
- Hover targets: hitbox strips with ~200ms open delay and debounced close ([ADR 0004](adr/0004-layer-surfaces-and-input.md)).

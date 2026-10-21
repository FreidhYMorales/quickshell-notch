# Apply progress: notch-foundation

Mode: Strict TDD (`node --test tests/`). Delivery: chained PRs, stacked-to-main.

## Completed tasks (cumulative)

- [x] 1.1-1.5 Reducer core (PR 1, branch `feat/notch-foundation-1-reducer-core`)

- [x] 2.1-2.5 Mid-flow rules (PR 2a, branch `feat/notch-foundation-2a-midflow`)

PR 2 was split to fit the 400-line budget: 2a = mid-flow rules, 2b = `centerView` (tasks 2.6-2.7). The chain is now 7 PRs.

- [x] 2.6-2.7 `centerView` (PR 2b, branch `feat/notch-foundation-2b-view`)

- [x] 3.1-3.4 `earGeometry` + `surfaceLayout` (PR 3, branch `feat/notch-foundation-3-geometry`)

- [x] 4.1-4.4 `palette` + `hyprDsp` logic (PR 4a, branch `feat/notch-foundation-4a-logic`)

PR 4 was split to fit the 400-line budget: 4a = pure logic, 4b = `config/` tokens + `Session`/`Hypr` services (tasks 4.5-4.6). The chain is now 8 PRs.

- [x] 4.5-4.6 `config/` tokens, `Session` + `Hypr` services (PR 4b, branch `feat/notch-foundation-4b-config-services`)

- [x] 5.1-5.3 Surfaces and shell (PR 5, branch `feat/notch-foundation-5-surfaces`)
- [x] 6.1-6.3 `CenterStore`, `CenterSurface`, `CenterIdle` (PR 6, branch `feat/notch-foundation-6-center`)

Remaining: none. Next: sdd-verify.

## TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 1.1/1.2 | `tests/centerState.test.mjs` | Unit | N/A (new) | Written; module not found | 9/9 | 2 monitors, on/off, unknown monitor | Clean |
| 1.3 | `tests/centerState.test.mjs` | Unit | 9/9 | Written; 5 failing | 19/19 | owner/non-owner, replace, toggle close, unknown monitor | Clean |
| 1.4 | `tests/centerState.test.mjs` | Unit | 19/19 | Written; 3 failing | 26/26 | normal vs critical, stale id, dismissed | Clean |
| 1.5 | `tests/centerState.test.mjs` | Unit | 26/26 | n/a | 26/26 | n/a | `unchanged` and `setGlobal` helpers shared |
| 2.1-2.4 | `tests/centerState.test.mjs` | Unit | 26/26 | Written; 15 failing | 48/48 | polkit match/other flow, hold with/without power menu, lock with/without polkit, owner vs other removal, DND normal vs critical, keyboard vs polkit mute | Clean |
| 2.5 | `tests/centerState.test.mjs` | Unit | 26/26 | covered by 2.1-2.4 | 48/48 | n/a | `cancelPolkit`, `suppressed`, `withHold` helpers |
| 2.6/2.7 | `tests/centerView.test.mjs` | Unit | N/A (new) | Written; module not found | 12/12 | every priority pair, owner vs other monitor, hover vs toastHover, unknown monitor | Clean |
| 2.4 fix | `tests/centerState.test.mjs` | Unit | 48/48 | Written; 2 failing | 50/50 | launcher vs polkit muting a critical toast | Clean |

## Work Unit Evidence (unit 1)

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/centerState.test.mjs`: pass 26, fail 0 |
| Runtime harness | N/A, pure logic |
| Rollback boundary | `shell/logic/centerState.mjs` + `tests/centerState.test.mjs` |

## Deviations / decisions

- Design leaves unspecified: `LauncherToggle` on the owner while power is open is ignored (power outranks launcher); `PowerOpen{action}` stores the action in `keyboard.sub`.
- `ScreensChanged` only adds monitors in PR 1; removal rules arrive in PR 2 (task 2.3).
- `.gitkeep` removed only from `shell/logic/`.

## Work Unit Evidence (unit 2)

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/centerState.test.mjs`: pass 50, fail 0 (`tests/`: 51 incl. smoke) |
| Runtime harness | N/A, pure logic |
| Rollback boundary | rule edits in `shell/logic/centerState.mjs` and their tests |

## PR 2a decisions

- `ScreensChanged` now treats `names` as the full screen set (drops absent monitors).
- Suppressed toasts (DND non-critical, or keyboard/polkit open) are dropped and set `blinkDot`. A critical toast muted by an open keyboard state or polkit is NOT dropped: it goes straight to the `indicator` phase (`!`), per the plan's "critical stays until dismissed" (coordinator fix).
- `HoldStart` is ignored unless a power menu is open and no polkit is active; `HoldComplete` emits `power.run` and clears the hold but leaves the menu open.
- `PolkitRequest` is ignored while locked or for unknown monitors.

## PR 2b decisions

- `viewFor` mode name is `power` (design vocabulary); `toast.paused = hovered || toastHovered`, `toast.expanded = hovered`.

## PR 3 evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 3.1/3.2 | `tests/earGeometry.test.mjs` | Unit | N/A (new) | Written; module not found | 10/10 | `earCubic` both extend sides and k=0; `notchPath` full and clamped at h=4; `cornerPath` all 4 anchors with hand-derived strings; unknown anchor | Clean (one generic `buildPath` for notch and corner) |
| 3.3/3.4 | `tests/surfaceLayout.test.mjs` | Unit | N/A (new) | Written; module not found | 7/7 | wide/narrow/tiny screens, per-monitor override, override over-cap, overlap sweep over 8 widths | Clean |
| 3.3 fix | `tests/surfaceLayout.test.mjs` | Unit | 7/7 | Written; 4 failing | 9/9 | OSD on top row at 1920, shrink at 1366, collapse at 800, 5-slot overlap sweep | Clean |

Work Unit Evidence (unit 3): focused `node --test tests/earGeometry.test.mjs tests/surfaceLayout.test.mjs` pass 17, fail 0. Runtime harness N/A (pure logic). Rollback: `shell/logic/{earGeometry,surfaceLayout}.mjs` + their tests.

PR 3 decisions:
- `earGeometry` generalizes the old static slots: one `buildPath` takes per-corner types (square, ear, round). An ear extends its entering endpoint when the previous clockwise corner is round, otherwise its leaving endpoint; `k` is clamped by the free edge length minus both adjacent radii. This reproduces the old NotchEarShape and CornerEarShape(topLeft) layouts.
- `cornerPath` returns `null` for an unknown anchor.
- `layoutFor` tokens (to be defined in `Layout.qml`, PR 4): `idleHeight, cornerWidth, osdWidth, gap, centerMaxWidth, centerMaxWidthByMonitor`. Corners shrink to half the screen on tiny screens; centre width = `min(per-monitor or default max, screen - 2*(corner+gap))`. `bl`/`vr` (brightness/volume OSDs) sit on the top row between each corner and the centre, centred in the free space; the centre is sized first and each OSD shrinks (down to 0) to keep a `gap` on both sides. All five slots are covered by the no-overlap sweep (coordinator fix: the first version put them on the screen edges, overlapping the corners).

## PR 4a evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 4.1/4.2 | `tests/palette.test.mjs` | Unit | N/A (new) | Written; module not found | 7/7 | valid, other wallpaper, uppercase hex, missing/non-string input, malformed JSON, missing colour, invalid hex | Clean |
| 4.3/4.4 | `tests/hyprDsp.test.mjs` | Unit | N/A (new) | Written; module not found | 12/12 | no args, dotted name, literals, tables, 12 invalid names, injection in name/string/table key, escapes, digit after control char, nesting depth | Control chars escaped with a char loop (deno `no-control-regex`) |


PR 4a decisions:
- `parsePalette` reads `colors.{primary,on_surface,on_surface_variant}.hex` (only 6-digit hex) and returns `{primary,onSurface,muted}`; matugen's light-mode question stays open (phase 7).
- `dspExpr(name, args[])`: args are string, finite number, boolean or plain-object tables (keys `^[A-Za-z_][A-Za-z0-9_]*$`, depth <= 3). Control chars escape as 3-digit decimal `\ddd`.
- Qt's V4 engine rejects optional catch binding (`catch {`): `.mjs` imported by QML must use `catch (_e)`. PR 5/6 must keep this in mind for any logic imported from QML.
Work Unit Evidence (unit 4a): focused `node --test tests/palette.test.mjs tests/hyprDsp.test.mjs` pass 19, fail 0. Runtime harness: N/A (pure logic; QML consumers land in PR 4b). Rollback: `shell/logic/{palette,hyprDsp}.mjs` + tests.

## PR 4b evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 4.5/4.6 | none (QML) | Runtime | `tests/` 101/101 | n/a | `make check` green; scratch `qs` run exercised every singleton | fallback vs matugen file palette, smoke vs non-smoke dispatch, invalid name | n/a |

Work Unit Evidence (unit 4b): runtime harness `make smoke` ("config loaded") plus a scratch `qs -p` script (not committed) that read `Fonts/Flags/Timings/Layout.tokens/Colours/Session/Hypr`: palette fell back without matugen file and switched to the file's `primary` when present; `Session.requestLock` fired once and left `locked` false; `Hypr.dispatch` returned false for a bad name and made no hyprctl call under `NOTCH_SMOKE=1`. Rollback: `shell/config/`, `shell/services/`, Makefile `QMLDIRS`.

PR 4b decisions:
- `Hypr.dispatch` returns false under smoke (nothing dispatched) and for rejected names (warns); true means handed to `hyprctl` via an argv list.
- `Session.locked` is read-only; `setLocked(bool)` and `requestLock()` are the only mutators.
- `Layout.tokens` bundles the `layoutFor` token shape (`osdWidth` 220); `earRadius`/`cornerRadius` added for `earGeometry`. Flags: `reserveSpace` true (ADR 0004), `showPlaceholders` false.
- Makefile `lint-qml` now passes `-i <qmldir>` for every `qmldir` (stricter, removes false "not declared as singleton" warnings). qmllint also confuses `palette.mjs` with the QML `palette` type; fixed by aliasing the import as `PaletteLogic`.

## PR 5 evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 5.1-5.3 | none (QML) | Runtime | `tests/` 101/101 | n/a | `make check` green (101 pass); scratch `qs -p` with `showPlaceholders` true loads with no warnings | hidden default (smoke), placeholders shown | n/a |
| fix | `tests/earGeometry.test.mjs` | Unit | 101/101 | runtime-only failure under V4 (not reproducible in Node) | 101/101 | existing path-string tests | `flatMap` and `Object.fromEntries` replaced by loops |

Work Unit Evidence (unit 5): focused `make check` (fmt-check, lint, 101 tests pass, smoke "config loaded"). Runtime harness: `NOTCH_SMOKE=1 qs -p` on a scratch copy with `showPlaceholders: true`: "Configuration Loaded", no warnings. Rollback: `shell/components/`, `shell/notches/{workspaces,osd,controlcenter}`, `shell/shell.qml`, `earGeometry.mjs` loops.

PR 5 decisions:
- `NotchSurface` computes its slot from `layoutFor(screen.width, screen.name, Layout.tokens)[slotName]`; `visible` is bound to `shown` only (binding on `slot.width` caused a binding loop because `screen` is assigned on show). Mask item `body` is 0x0 when hidden, so hidden placeholders pass clicks through.
- `SpacerSurface` is the only surface with `ExclusionMode.Auto` + `exclusiveZone`; inert (Ignore, zone 0) under smoke or `reserveSpace=false`.
- V4 lacks `Object.fromEntries` and `Array.flatMap`: found only at runtime, fixed in `earGeometry.mjs`, recorded in AGENTS.md.
- qmllint cannot resolve `PanelWindow` (uncreatable) so `NotchSurface`/`SpacerSurface` carry tool-only warnings; `make lint` exits 0.
- `shell.qml` root is `Scope`; the centre slot has no surface until PR 6.

## PR 6 evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 6.1-6.3 | none (QML) | Runtime | `tests/` 101/101 | smoke failed: V4 rejected object spread in `centerState.mjs` | `make check` green; scratch `qs -p` loads | n/a | n/a |
| fix | `tests/v4Compat.test.mjs` | Unit | 101/101 | Written; 1 failing (object spread in `centerState.mjs`) | 102/102 | scans every `shell/logic/*.mjs` | `merge` helper (`Object.assign`) replaces spread |

Work Unit Evidence (unit 6): `make check` (fmt-check, lint, 102 tests pass, smoke "config loaded"). Runtime harness: scratch copy run with `timeout 8 qs -p`: "Configuration Loaded", no errors (only an unrelated portal warning). Hover/hot-plug not exercised headlessly: manual checks listed in the PR. Rollback: `shell/notches/center/`, the `CenterSurface` entry in `shell/shell.qml`, `merge` edits in `centerState.mjs`, `tests/v4Compat.test.mjs`.

PR 6 decisions:
- `CenterStore` is a `pragma Singleton` holding `state`; `dispatch(event)` reduces and runs effects; effects (`polkit.cancel`, `power.run`) are logged only until their services exist. It listens to `Quickshell.screensChanged` and `Session.lockedChanged`.
- `CenterSurface` reads `CenterStore.viewFor(screen.name)`; hover (debounced by `NotchZone`) dispatches `Hover`. `Expanded` has no content yet, so every mode paints `CenterIdle`.
- Deviation: Qt V4 rejects object spread, which broke the reducer at load (Node accepts it). `centerState.mjs` now uses a `merge` helper; `tests/v4Compat.test.mjs` guards it. Recorded in AGENTS.md.
- Under smoke the centre loads and registers nothing global (the reducer is pure; effects only log).

## Post-apply fixes (branch `fix/notch-ears`)

Found in the user's visual check after merge (70cb4de).

| Fix | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| Bug 1: concave ears were inverted | `tests/earGeometry.test.mjs` | Unit | 102/102 before | Expectations rewritten to the correct shape: 12 of 13 failing | 13/13 in file; 108/108 overall | two `notchPath` sizes, all four `cornerPath` anchors, tangent and on-circle concavity checks, clamping at small h and narrow w | One `serialise` plus `mirror` (topLeft built once, other anchors mirrored; single-axis flip reverses arc sweep) replaced the per-corner `buildPath` |
| Bug 2: idle notch used the full 600 px | none (QML) | Runtime | 108/108 | n/a | `make check` green (fmt, lint, 108 tests, smoke) | n/a | n/a |

Note: the old tests pinned the INVERTED shape (convex corners cutting the box). They were replaced, not weakened. `earCubic` (the port of the old EarCurve.js) was removed with them; nothing else used it.

Decisions:
- `notchPath`: top edge spans the full width, body sides at x = er and x = w - er, ears are quarter circles (KAPPA 0.5523) centred on the top edge; bottom corners convex with radius cr. Clamps: er <= min(h, w/2), cr <= min(h - er, w/2 - er); a zero radius emits no arc.
- `cornerPath`: built for topLeft (edges flare to the far corners, body sides inset by er, opposite corner round) and mirrored for the other anchors. Clamps: er <= min(h, w)/2, cr <= min(h, w) - 2*er.
- Deviation from the brief: the right-ear second control point is (w - er, er - KAPPA*er), the exact mirror of the left ear (a true quarter circle), not (w - er, KAPPA*er). The brief's concavity check "x < er/2" is also wrong for a quarter circle centred at (0, er): the midpoint is (0.707er, 0.293er). Tests assert y < er/2 and distance to the circle centre = er.
- `Layout.idleWidth` = 260 (includes the 2 * earRadius flare). `NotchSurface` gains `maskItem` (default `body`); `CenterSurface` sets it to the idle item, so clicks beside the notch pass through. `CenterIdle` is `min(idleWidth, surface width)` wide, centred, 0 wide when hidden. `NotchZone` is anchored to the idle item. The surface stays fixed-size.

Work Unit Evidence (post-apply): focused `node --test tests/earGeometry.test.mjs` 13 pass, 0 fail. `make check` exit 0 (fmt-check, lint with the same 7 pre-existing qmllint warnings, 108 tests, smoke "config loaded"). Rollback: `shell/logic/earGeometry.mjs` + test (commit 1); `Layout.qml`, `NotchSurface.qml`, `CenterIdle.qml`, `CenterSurface.qml` (commit 2).

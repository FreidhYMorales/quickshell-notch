# Verify report: notch-foundation

Mode: Strict TDD (runner `node --test tests/`), artifact store openspec. Verdict: **PASS WITH WARNINGS**.

Envelope counts: 31 requirements, 51 scenarios; CRITICAL 0, WARNING 4, SUGGESTION 3.

## Completeness

All 24 tasks (1.1-6.3) are `[x]` and match code state (6 logic modules, config/services/components/notches, shell.qml present). No pending task.

## Execution evidence

| Command | Exit | Result |
|---|---|---|
| `node --test tests/` | 0 | 108 pass, 0 fail |
| `make check` | 0 | fmt-check, lint, 108 tests pass, smoke "config loaded" |
| `node --test --experimental-test-coverage tests/` | 0 | logic 100% line, 99.04% branch (centerState.mjs 97.85% branch) |

No long-running shell started; the user's running shell was untouched.

## TDD compliance (strict)

| Check | Result | Details |
|---|---|---|
| TDD evidence table in apply-progress | ok | present, per work unit |
| Tests exist for logic tasks | ok | 8 test files; tasks 1.x-4.4 all have RED/GREEN rows |
| GREEN on execution | ok | 108/108 now |
| Triangulation | ok | multiple cases per behaviour in every row |
| Safety net for modified files | ok | recorded for each follow-up |
| QML tasks 4.5, 4.6, 5.x, 6.x | warning | no committed tests; runtime evidence only (scratch `qs -p` runs, not committed), by design (QML not testable in node) |

Post-apply ear fix: tests were rewritten (they pinned the inverted shape), RED recorded (12 of 13 failing). Acceptable.

Assertion quality audit: no tautologies, no ghost loops (loops iterate over fixed non-empty arrays; `v4Compat` scans a non-empty dir), the `deepEqual(effects, [])` checks accompany state assertions. 0 CRITICAL, 0 WARNING.

Layers: Unit 108 tests (8 files); no integration/E2E tooling (QML runtime is manual).

## Spec compliance matrix

Legend: COMPLIANT = covering test passed; STATIC = verified by source scan in this run; MANUAL = runtime/visual only; PARTIAL.

### center-notch-state (13 req, 25 scenarios)

| Scenario | Status | Evidence |
|---|---|---|
| Same input, same output | COMPLIANT | centerState.test.mjs:28 |
| Fresh monitor | COMPLIANT | centerState.test.mjs:7, centerView.test.mjs:12 |
| Higher beats lower | COMPLIANT | centerView.test.mjs:87 |
| Lower does not displace higher | PARTIAL | centerView.test.mjs:93 (mode holds); "toast stays queued" not implemented, see W1 |
| Polkit tops all | COMPLIANT | centerView.test.mjs:105 |
| Hover on A only | COMPLIANT | centerState.test.mjs:39 |
| Leave | COMPLIANT | centerState.test.mjs:50 |
| Preempt and return | COMPLIANT | centerView.test.mjs:31 |
| Hover expands visible toast | COMPLIANT | centerView.test.mjs:40, :57 |
| Queue order (+1) | PARTIAL | not implemented: newer toast replaces (centerState.test.mjs:210), see W1 |
| DND | COMPLIANT | centerState.test.mjs:460 |
| Critical bypasses DND | COMPLIANT | centerState.test.mjs:469 |
| Launcher on A mutes B | COMPLIANT | centerState.test.mjs:478 |
| Dismiss everywhere | COMPLIANT | centerState.test.mjs:252 (toast slot is global) |
| Collapse | COMPLIANT | centerState.test.mjs:228; muted variant :496 (reconciled: goes to indicator) |
| Expanded reachable | COMPLIANT | centerView.test.mjs:64 |
| Cleared on dismiss | COMPLIANT | centerState.test.mjs:252 |
| Polkit cancels hold | COMPLIANT | centerState.test.mjs:295 |
| Return to previous | COMPLIANT | centerView.test.mjs:105 |
| Lock closes all | COMPLIANT | centerState.test.mjs:386 |
| Open while locked | COMPLIANT | centerState.test.mjs:405 |
| Non-owner ignored | COMPLIANT | centerState.test.mjs:179 |
| Owner change does not move | COMPLIANT (reconciled) | centerState.test.mjs:179 |
| Remove polkit host | COMPLIANT | centerState.test.mjs:431 |
| Remove other monitor | COMPLIANT | centerState.test.mjs:440 |

### hypr-dispatch (3 req, 4 scenarios)

| Scenario | Status | Evidence |
|---|---|---|
| Search | STATIC | `rg hl.dsp shell`: only services/Hypr.qml and logic/hyprDsp.mjs (builds the expression for Hypr) |
| Valid | COMPLIANT (logic) | hyprDsp.test.mjs:5-27 build the call; the QML forward is MANUAL (scratch run in apply-progress) |
| Unknown | COMPLIANT (logic) | hyprDsp.test.mjs:28, :49 return null; warn path MANUAL (scratch) |
| Smoke | STATIC + smoke | Hypr.qml:17 returns before any call under `Flags.smoke`; `make smoke` passes |

### session-service (4 req, 4 scenarios)

| Scenario | Status | Evidence |
|---|---|---|
| Defaults | MANUAL | scratch run only (apply-progress 4b); Session.qml read-only `locked` |
| Request | MANUAL | scratch run: fired once, `locked` false |
| Set | MANUAL | `setLocked` exists; `lockedChanged` wired in CenterStore.qml:52 |
| Search (Visibilities) | STATIC | `rg Visibilities shell`: 0 matches |

### shell-surfaces (7 req, 11 scenarios)

| Scenario | Status | Evidence |
|---|---|---|
| Two monitors | MANUAL | shell.qml creates spacer, C, TL(workspaces), BL, VR, TR per screen via Variants; idle centre shown |
| Hot-plug | MANUAL | Variants over `Quickshell.screens` + `ScreensChanged` reducer tests (:74, :421-440); runtime not exercised |
| Reserved strip | MANUAL | SpacerSurface.qml:19-20 (Auto + `Layout.idleHeight`) |
| Toggle off | STATIC | SpacerSurface.qml:10 reserve false gives Ignore, zone 0 |
| Click-through | MANUAL, user confirmed | mask is the idle item (`maskItem`) |
| Hover on notch | MANUAL | NotchZone anchored to idle item; runtime hover not exercised headlessly |
| Debug placeholders | MANUAL | scratch run with `showPlaceholders` (apply-progress PR 5) |
| Each corner (ears) | COMPLIANT (geometry) + MANUAL | earGeometry.test.mjs:109-141 all four anchors, concavity :79; visual confirmed by user |
| Idle | MANUAL / STATIC | CenterIdle.qml:25 `Strings.center`, black |
| Smoke run | COMPLIANT | `make smoke` exit 0 "config loaded"; spacer inert under smoke; the other smoke-skipped services do not exist yet |
| Normal run | MANUAL | SpacerSurface reserve per `reserveSpace` |

### visual-tokens (4 req, 7 scenarios)

| Scenario | Status | Evidence |
|---|---|---|
| Import | COMPLIANT | `make smoke` loads; `rg` shows singletons used from shell |
| Literal scan | STATIC | no colour/font/duration literal outside shell/config (rg, this run) |
| Swap (font) | MANUAL | Fonts singleton only |
| Max width | COMPLIANT | surfaceLayout.test.mjs:23, :35, :40, :53 |
| Two wallpapers | COMPLIANT (parse) | palette.test.mjs:16, :24 |
| Light mode | PARTIAL | parser reads the dark scheme fixture only (palette.test.mjs:7); no light-mode input test, see S2 |
| No matugen output | COMPLIANT | palette.test.mjs:38-57 return null; QML fallback checked in scratch run |

### Totals

Requirements 31: 31 implemented. Scenarios 51: 31 COMPLIANT by passing tests or reconciled equivalents, 5 STATIC, 12 MANUAL-only, 3 PARTIAL. No scenario FAILING.

## Design coherence

Reducer is a single root `{global, monitors{}}` returning `{state, effects}`; `viewFor` derives mode; vocabulary per tasks.md reconciliations; OSD on top row; `idleWidth` token; V4 compatibility guarded by `tests/v4Compat.test.mjs`. No unreconciled deviation found.

## Issues

### CRITICAL
None.

### WARNING
- W1: Spec "Queue order" (`+1`) and "toast stays queued" are not implemented: a single toast slot, a newer toast replaces the current one, suppressed toasts are dropped and set `blinkDot`. Not listed in the known reconciliations; confirm it is intentionally deferred (notifications phase) and note it in archive.
- W2: Session and Hypr QML behaviour (spec session-service Defaults/Request/Set, hypr Valid/Unknown forward and warning) has no committed repeatable test; evidence is an uncommitted scratch run.
- W3: Twelve scenarios are MANUAL only: hot-plug, hover runtime, spacer reserved strip, two-monitor surface set, placeholders, normal run. Reducer-side hot-plug is tested.
- W4: tasks 4.5-4.6 and 5.x-6.x have no test-first evidence (QML), accepted by project config but unverifiable.

### SUGGESTION
- S1: Add a static test that asserts the `hl.dsp` and `Visibilities` greps and the literal scan, so those scenarios become repeatable.
- S2: Add a palette test with a light-scheme matugen fixture proving dark values still win.
- S3: centerState.mjs branch coverage 97.85%; the uncovered branch is defensive.

## Manual-check list

| Check | Status |
|---|---|
| Ears concave and correct | confirmed by user |
| Bottom corner radius | confirmed by user |
| Clicks pass through beside the notch | confirmed by user |
| Monitor hot-plug (add then remove second monitor, first unaffected) | pending |
| Hover opens expanded, debounced, per monitor | pending |
| Two monitors: six surfaces each, idle text on black | pending |
| Reserved strip equals idle height on all monitors; off at top edge | pending |
| `showPlaceholders = true` shows the four placeholders with masks and ears | applied in scratch run, visual pending |
| Palette differs per wallpaper with matugen output | pending |

## Recommendation

Next: sdd-archive. W1 should be acknowledged by the user before archive; no blocking issue.

## Resolutions (2026-10-21)

- W1 accepted as an intentional deferral: the toast queue and its `+N` counter belong to the rewritten `Notifs` service in the `notch-notifications` change (plan: "single queue timer, replaces-id handling"). The reducer keeps one visible toast slot ("newest shown"); suppressed toasts only set `blinkDot` here, and their history lives in `Notifs`. Carry "Queue order (+1)" and "toast stays queued" into that change's spec.
- W2/W4 accepted per ADR 0003: only `shell/logic` is unit-tested; QML is covered by smoke plus manual checks.
- Manual checks confirmed by the user: concave ears, bottom corner radius, click-through beside the notch, hover runtime (no errors in the log).
- Manual checks pending (no second monitor available yet): monitor hot-plug, multi-monitor reserved strip and surface set, `showPlaceholders` visuals, per-wallpaper palette with real matugen output. Re-check in a later phase.

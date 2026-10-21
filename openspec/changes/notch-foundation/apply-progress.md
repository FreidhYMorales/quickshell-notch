# Apply progress: notch-foundation

Mode: Strict TDD (`node --test tests/`). Delivery: chained PRs, stacked-to-main.

## Completed tasks (cumulative)

- [x] 1.1-1.5 Reducer core (PR 1, branch `feat/notch-foundation-1-reducer-core`)

- [x] 2.1-2.5 Mid-flow rules (PR 2a, branch `feat/notch-foundation-2a-midflow`)

PR 2 was split to fit the 400-line budget: 2a = mid-flow rules, 2b = `centerView` (tasks 2.6-2.7). The chain is now 7 PRs.

- [x] 2.6-2.7 `centerView` (PR 2b, branch `feat/notch-foundation-2b-view`)

- [x] 3.1-3.4 `earGeometry` + `surfaceLayout` (PR 3, branch `feat/notch-foundation-3-geometry`)

Remaining: Phases 4-6.

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

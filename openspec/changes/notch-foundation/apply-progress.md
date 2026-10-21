# Apply progress: notch-foundation

Mode: Strict TDD (`node --test tests/`). Delivery: chained PRs, stacked-to-main.

## Completed tasks (cumulative)

- [x] 1.1-1.5 Reducer core (PR 1, branch `feat/notch-foundation-1-reducer-core`)

- [x] 2.1-2.5 Mid-flow rules (PR 2a, branch `feat/notch-foundation-2a-midflow`)

PR 2 was split to fit the 400-line budget: 2a = mid-flow rules, 2b = `centerView` (tasks 2.6-2.7). The chain is now 7 PRs.

Remaining: 2.6-2.7 (PR 2b), Phases 3-6.

## TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 1.1/1.2 | `tests/centerState.test.mjs` | Unit | N/A (new) | Written; module not found | 9/9 | 2 monitors, on/off, unknown monitor | Clean |
| 1.3 | `tests/centerState.test.mjs` | Unit | 9/9 | Written; 5 failing | 19/19 | owner/non-owner, replace, toggle close, unknown monitor | Clean |
| 1.4 | `tests/centerState.test.mjs` | Unit | 19/19 | Written; 3 failing | 26/26 | normal vs critical, stale id, dismissed | Clean |
| 1.5 | `tests/centerState.test.mjs` | Unit | 26/26 | n/a | 26/26 | n/a | `unchanged` and `setGlobal` helpers shared |
| 2.1-2.4 | `tests/centerState.test.mjs` | Unit | 26/26 | Written; 15 failing | 48/48 | polkit match/other flow, hold with/without power menu, lock with/without polkit, owner vs other removal, DND normal vs critical, keyboard vs polkit mute | Clean |
| 2.5 | `tests/centerState.test.mjs` | Unit | 26/26 | covered by 2.1-2.4 | 48/48 | n/a | `cancelPolkit`, `suppressed`, `withHold` helpers |
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

# Apply progress: notch-foundation

Mode: Strict TDD (`node --test tests/`). Delivery: chained PRs, stacked-to-main.

## Completed tasks (cumulative)

- [x] 1.1-1.5 Reducer core (PR 1, branch `feat/notch-foundation-1-reducer-core`)

Remaining: Phases 2-6 (PRs 2-6).

## TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|---|
| 1.1/1.2 | `tests/centerState.test.mjs` | Unit | N/A (new) | Written; module not found | 9/9 | 2 monitors, on/off, unknown monitor | Clean |
| 1.3 | `tests/centerState.test.mjs` | Unit | 9/9 | Written; 5 failing | 19/19 | owner/non-owner, replace, toggle close, unknown monitor | Clean |
| 1.4 | `tests/centerState.test.mjs` | Unit | 19/19 | Written; 3 failing | 26/26 | normal vs critical, stale id, dismissed | Clean |
| 1.5 | `tests/centerState.test.mjs` | Unit | 26/26 | n/a | 26/26 | n/a | `unchanged` and `setGlobal` helpers shared |

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

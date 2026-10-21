# Apply progress: notch-workspaces-osd

Mode: Strict TDD. Chain: stacked-to-main.

## PR 1 of 5: workspaceStrip (tasks 1.1-1.7) - done

| Task | RED (observed) | GREEN | Triangulation |
|------|----------------|-------|---------------|
| 1.1/1.2 | module not found | filter + focus tests pass | 11 filter rows, tie, thresholds |
| 1.3-1.5 | `slotRange is not defined`, missing exports | strip tests pass | range rows, isolation, flash, pin |
| 1.6/1.7 | missing export `diffSnapshots` | 29/29 pass | open, move, special, cross-monitor |

Focused test: `node --test tests/workspaceStrip.test.mjs`, 29 pass, 0 fail.
Runtime harness: N/A, pure logic. Rollback: delete `shell/logic/workspaceStrip.mjs` and `tests/workspaceStrip.test.mjs`.

Decisions and deviations:

- `slotRange({activeId, windows, monitor, minSlots})` replaces design `pageStart`; `stripFor` and `slotRange` filter by `monitor` themselves.
- A float is a popup when either side is below `minFloatWidth`/`minFloatHeight`.
- A move to a special workspace is a `move`; a cross-monitor move reaches both monitors.
- `stripFor` with a special returns `items: []`; QML paints the Arch icon.

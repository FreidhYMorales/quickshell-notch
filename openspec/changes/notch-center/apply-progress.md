# Apply progress: notch-center

Mode: Strict TDD. Runner: `node --test tests/`. Chain: stacked-to-main.

## PR 1 of 5: battery and sysStats rules (tasks 1.1-1.4, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 1.1/1.2 | `tests/battery.test.mjs` | Unit | N/A (new) | Written; `ERR_MODULE_NOT_FOUND` before `battery.mjs` existed | 11/11 pass | Multiple inputs per rule (table, boundaries 19/20, re-arm) | None needed |
| 1.3/1.4 | `tests/sysStats.test.mjs` | Unit | N/A (new) | Written; `ERR_MODULE_NOT_FOUND` before `sysStats.mjs` existed | 7/7 pass | Two samples per parser plus malformed cases | None needed |

Total: 18 new tests, full suite 126/126.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/battery.test.mjs tests/sysStats.test.mjs` passes |
| Runtime harness | N/A: pure logic, no runtime boundary |
| Rollback | Delete `shell/logic/{battery,sysStats}.mjs` and their two tests |

### Notes

- `fromUPower` takes `fraction` in 0-1 (verified on host: 0.34 at 34%).
- `classify`: a plugged battery that is neither charging nor full gives `none`.
- The battery test file was condensed after the first pass to fit the 400-line budget.

## Coordinator fix (PR 1)

- `classify` returns `plugged` (not `none`) when on AC but neither charging nor full, e.g. the user's laptop held at an 80% charge limit (UPower `pending-charge`). User chose a "plugged" variant of the charging layer: same symmetric layout, plug icon instead of the bolt, no animation. RED: spec-table test failed (2 new rows); GREEN after the change. PR 3/4 must add the plug glyph to `Strings` and render the `plugged` layer.

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

## PR 2 of 5: calendar, media, layout, format rules (tasks 2.1-2.7, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 2.1/2.2 | `tests/calendar.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` before `calendar.mjs` | 10/10 | 5 spec-table rows, radius, weekday, midnight | None needed |
| 2.3/2.4 | `tests/media.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` | 8/8 | 4 table rows, empty, switch, fallbacks | None needed |
| 2.5/2.6 | `tests/centerLayout.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` | 12/12 | 5 layers incl. `plugged`, cap, 4 expanded rows, shapeFor | None needed |
| 2.7 | `tests/format.test.mjs` | Unit | N/A (new) | `ERR_MODULE_NOT_FOUND` | 6/6 (one test typo fixed, not the code) | 4 clock rows, 2 date cases | None needed |

Total: 36 new tests, full suite 162/162. `make check` green.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/calendar.test.mjs tests/media.test.mjs tests/centerLayout.test.mjs tests/format.test.mjs`: 36 pass, 0 fail |
| Runtime harness | N/A: pure logic, no runtime boundary |
| Rollback | Delete `shell/logic/{calendar,media,centerLayout,format}.mjs` and their four tests |

### Notes

- `idleWidth({base, side, layer, max})` grows for every layer other than `none` (charging, plugged, full, low).
- `weekStrip` adds `weekday` (0 = Monday) per the design contract.
- `shortDate` and `clock` take names and numbers only; no locale use.

## PR 3 of 5: services, tokens, surface height (tasks 3.1-3.7, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 3.1 | `tests/surfaceLayout.test.mjs` | Unit | 9/9 existing | 2 new tests; with the old `surfaceLayout.mjs`: 10 pass, 1 fail | 11/11 | With and without `expandedHeight`; other slots unchanged | None needed |
| 3.2-3.5 | N/A (QML) | Config / service | `make check` before | N/A: no logic; rules live in tested `.mjs` | `make check` green (164 tests, qmllint, smoke) | Scratch probe against live UPower, `/proc`, SystemClock | None needed |
| 3.6 | N/A | Verification | N/A | N/A | Confirmed 0-1 (0.34 at 34%, coordinator probe 2026-10-21); the scratch probe read 30 after rounding | N/A | N/A |
| 3.7 | N/A | Docs | N/A | N/A | AGENTS.md updated; `make smoke` loads | N/A | N/A |

Total: 2 new tests, full suite 164/164. `make check` green.

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/surfaceLayout.test.mjs`: 11 pass, 0 fail |
| Runtime harness | `make smoke`: config loaded. Scratch probe (`qs -p` on a throwaway shell in the session scratchpad, timeout 15, not left running): `Battery` present=true plugged=false percentage=30 layer=none (the first read at startup was present=false and 0, then updated through signals); `Mpris` hasPlayer=false with fallback text; `SysInfo` cpu=2 ram=16; `Time` 13:02, "Oct 21", 2026-10-21 |
| Rollback | Revert the three commits: `shell/config/*` additions, `shell/services/{Battery,Time,Mpris,SysInfo,Recorder}.qml` + `qmldir`, `surfaceLayout.mjs` + test, `AGENTS.md` lines |

### Notes

- `Battery` touches `UPower.displayDevice` at startup (`Component.onCompleted: refresh()`) and refreshes from `Connections` on `ready`, `isPresent`, `state`, `percentage`, `isLaptopBattery` and `UPower.onBattery`; no timer.
- Deviation: `Time.day` is named `dayOfMonth`, because a `day` property would collide with the designed `dayChanged` signal (QML rejects the duplicate change signal).
- Singletons are lazy: `SysInfo` only polls once something reads it. PR 4's idle row (its consumer) triggers that. Under `Flags.smoke` its timer never runs.
- Added `Layout.batterySide`, `expandedWidth`, `expandedClockWidth`, `expandedHeight` (also in `tokens`); `Strings.glyphBolt` and `glyphPlug`; `Flags.batteryOverride`; `Timings.sysPoll`.

## PR 4 of 7: idle row, battery layers, shape and mask (tasks 4.1-4.5, done)

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 4.3 (`formatPercent`, the one new rule) | `tests/format.test.mjs` | Unit | 162 pass before | 4 new cases; `SyntaxError: no export named 'formatPercent'` | 10/10 in file, 168/168 suite | 72.4, 71.6, 100, 0 | None needed |
| 4.1, 4.2, 4.4 | N/A (QML) | Component / surface | `make check` before | N/A: no logic; widths, layers and shape come from tested `.mjs` | `make check` green; scratch `qs -p` probes | Seven battery scenarios (see below) | None needed |
| 4.3 (idle row) | N/A (QML) | Component | as above | N/A | as above | clock offset 0 in every layer | None needed |
| 4.5 | N/A | Manual / scratch | N/A | N/A | Scratch probe log, see below | N/A | N/A |

Total: 4 new tests, full suite 168/168. `make check` green (qmlformat, qmllint, deno, node tests, smoke).

### Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test | `node --test tests/format.test.mjs`: 10 pass, 0 fail |
| Runtime harness | Scratch copy of `shell/` in the session scratchpad run with `timeout 6 qs -p`, with `Flags.batteryOverride` set per scenario and a probe timer in `CenterIdle` (never left running). `layer / glyph / pct / notch width / clock offset`: none 260 offset 0; charging bolt U+f0e7 72% 332; plugged plug U+f1e6 80% 332; full battery U+f240 100% 332; low 19% battery-low U+f243 332; 20% gives none 260; 9% unplugged plus `Recorder.recording=true`: low, rec true. Re-arming the one-shot in the scratch store logged `CenterStore: battery critical (9%)`. Real battery read 29% (layer none); `ram=16`; `cpu=null` at 1.5 s (first sample, ring at 0) |
| Rollback | Revert the `feat(center)` commit: `components/{ArcMeter,NotchZone}.qml`, `qmldir`, `notches/center/*`, token additions; the `formatPercent` commit is independent |

### Notes

- Deviation: `CenterIdle` property named `batteryLayer` (not `layer`): `layer` is a final `Item` property and the shell failed to load.
- `CenterIdle` reads `Battery` and `SysInfo`, so both lazy singletons start at load.
- The shape item (width follows `idleWidth`, clipped, `Behavior` with `Anim`) is the mask and the `NotchZone` area. Expanded shape reuses the idle size until PR 5.
- `NotchZone.openDelay` (default `Timings.hoverOpen`) applies to hover on; hover off keeps `Timings.hoverDebounce`.
- New tokens: `Layout.{arcSize,arcRing,arcIcon,dotSize,rowGap}`, `Colours.recording`, `Timings.blink`, `Fonts.{body,small}`, `Strings.{glyphCpu,glyphRam,glyphBatteryFull,glyphBatteryLow,dateTimeSeparator}`.
- Startup caveat: the critical log is lost if the battery is already at or below 10% when the shell starts (the store's `Connections` attach after the first `Battery.refresh()`); later transitions log normally.
- Rec dot sits left of the row, unread dot right of it (both outside the clock layout). The unread source is not wired in this change.

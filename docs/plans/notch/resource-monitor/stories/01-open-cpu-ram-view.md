# Story 01: Open the CPU and RAM resource view

## Story

01. As a Control Center user, I want to open the resource view and see current CPU and RAM usage so that I can inspect system load at a glance.

## Acceptance criteria

- [ ] Given the Control Center is open, when I activate its resource entry, then a dedicated resource view opens and shows the current CPU and RAM usage.
- [ ] Given CPU or RAM has no usable reading yet or its source is unavailable, when the resource view is shown, then that metric is identified as measuring or unavailable rather than displayed as zero.
- [ ] Given the resource view is open, when I use its back control or Escape, then I return to the Control Center root.

## Plan

- Add a resource entry to the Control Center that opens a dedicated subpage.
- Show the existing CPU and RAM readings in that view, with a clear status when a reading is not usable.
- Preserve the established Control Center navigation behavior for returning to the root.
- Verify the view and its navigation with focused tests or probes.

## Out of scope

- Compact CPU/RAM/disk summary widget.
- Additional CPU details, storage, network, GPU, NPU, or temperature metrics.
- Polling lifecycle changes; these are covered by story 09.
- The complete resource grid and bounded scrolling.

## Suggestions (your call)

- The existing notifications subpage and `SysInfo` service provide direct patterns for this slice.

## Size

small
Risk: none

## Log

- L1 request: Load the `flow-story` skill and follow it. 01
- Red attempt: `node --test tests/qml/controlcenter-resource.mjs` failed because the resource entry is missing.
- Paused before the test commit: the test step added 77 lines across two files, exceeding the flow-pair ~50-line step limit; it needs a smaller slice.
- Approved smaller slice: first verify that the resource entry opens its view; later verify CPU/RAM rendering separately.
- Test commit: `a9de901 test(controlcenter): open resource view`; red output: `resource view: entry is missing`.
- Paused after two failed green attempts: the entry was added, but both the `TapHandler` and `MouseArea` activation attempts failed with `resource view: entry did not open the view`.
- No production commit was made. The marker is removed while the implementation failure is investigated.
- Retry in a fresh worktree: first visible-view cycle passed (`fcb5593` → `4e2c927`).
- CPU/RAM rendering test commit `b859ad4` is red. Its fixture sets `SysInfo` values before creating the Control Center; the service's initial asynchronous `/proc` reads may overwrite them.
- Paused before further implementation: the committed test would need a setup correction, which flow-pair forbids editing in place.
- Values-cycle retry in a fresh worktree: the corrected fixture waits for the initial `SysInfo` readings before injecting 37% CPU and 62% RAM. The committed test `812fa99` still fails.
- Diagnosis: `Visual.textsIn(item)` expects a single item and walks its `children`, but the test passes `root.target.content`, which is the `body.data` array exposed by `NotchSurface`. The helper therefore sees no children and always returns an empty list. Use `Visual.findText(root.target.content, text)` for each expected label/value, or call `textsIn` on an actual item.
- Stopped before a second implementation attempt; the current production edits are uncommitted and the red marker is removed.
- Second retry: `be9596e` uses `Visual.findText` on each expected string, but the fixture's `Services.SysInfo` import does not expose usable readings: after injecting the values, both properties log as `undefined`; the null checks also pass incorrectly because `undefined !== null`.
- A diagnostic probe confirmed the UI bindings render 37%/62% when values are injected after the initial read through the same live service instance. The test needs a reliable fixture before implementation can be judged; stopped with production changes uncommitted and red marker removed.
- Approved retry: `resourceStats` is injectable for deterministic tests and defaults to the live `SysInfo` singleton.
- Values cycle passed: `5f6552a` → `11637f3`; invalid-reading status cycle passed: `e48cc5e` → `bd33044`.
- Back control cycle passed: `8382940` → `e9b1b4c`; Escape cycle passed: `c30fd0d` → `7392ca6`.
- Focused regression run: 10 tests passed, 0 failed.
- Full `make check`: unit tests passed (736), but the existing `tests/qml/power-dry-run.mjs` tests fail because they expect `hyprctl dispatch hl.dsp.exit()` while unchanged `shell/logic/powerMenu.mjs` uses `uwsm stop`. Both files match `main`; no unrelated test was changed.
- Paused before closing the story because the project test command remains red and fixing the existing power tests would require changing tests outside this story. `make check-fast` passes.

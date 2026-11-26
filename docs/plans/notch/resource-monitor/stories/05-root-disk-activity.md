# Story 05: Show root disk activity

## Story

05. As a user troubleshooting storage, I want read/write rates when the backing device can be identified reliably so that I can see current disk activity.

## Acceptance criteria

- [ ] Given at least one Control Center is open and the root filesystem's backing block device is identified with two valid samples, when the resource view is shown, then it displays read and write rates for that device in clear human-readable units; after the last Control Center closes, sampling stops.
- [ ] Given a rate is still measuring or the root device/counters cannot be identified or read reliably, when the resource view is shown, then the storage rates are labeled with their status rather than shown as zero.
- [ ] Given disk counters reset, roll back, or have an invalid sample interval, when a rate is calculated, then it is unavailable rather than a misleading value.

## Plan

- Identify the block device directly associated with the root filesystem; do not guess or aggregate ambiguous backing devices.
- Derive read and write rates from valid consecutive kernel counter samples and elapsed time.
- Reuse the existing active-only, smoke-disabled sampling window.
- Show the rates in the existing storage details with clear labels and units.
- Keep initial, unavailable, and invalid readings explicit.
- Verify device selection, rate calculations, resets, and presentation with deterministic tests.

## Out of scope

- Per-process or per-application disk activity.
- Rates for arbitrary mounts or a device picker.
- Aggregating physical devices behind layered or multi-device filesystems.
- General polling lifecycle changes, covered by story 09.
- Resource-grid scrolling and focus behavior, covered by story 07.

## Suggestions (your call)

- The approved plan calls for kernel counter deltas normalized by elapsed time and treating ambiguous devices, resets, rollback, and invalid intervals as unavailable.

## Size

normal
Risk: item 4 (shared resource sampling state)

## Log

- L1 request: okay, sigamos con la siguiente storie
- Approved test list: root-device rate calculation, unusable device/counter/interval handling, active-only lifecycle integration, and smoke-mode integration.
- Rate-calculation unit cycle: `9cd2fc0` red -> `62ca9ea` green (`node --test tests/sysStats.test.mjs`, 12/12).
- Unusable-sample test `6b599c8` is red as expected: incomplete mountinfo was incorrectly accepted and produced rates. Before production changes, stopped because formatting the new test also reformatted four lines in the already committed rate test (flow-pair stop rule 3). Risk: item 4 (shared resource sampling state); your call.
- User approved keeping that formatting-only normalization. Unusable-sample cycle `6b599c8` -> `d3bea6b` is green (`tests/sysStats.test.mjs`, 13/13).
- Lifecycle integration probe currently fails because diskstats acquisition is not implemented. The probe is 62 lines across two files, exceeding the ~50-line step limit; stopped before committing the test or writing production code. Probe files remain untracked. Risk: item 4 (shared resource sampling state); your call.

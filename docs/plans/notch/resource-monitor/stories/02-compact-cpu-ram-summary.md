# Story 02: Compact CPU/RAM summary

## Story

02. As a Control Center user, I want a compact CPU/RAM summary and a central notch that shows only date and time so that resource details stay in the Control Center.

## Acceptance criteria

- [ ] Given CPU and RAM readings are usable, when the Control Center root is open, then a compact summary shows both labeled percentages in stable positions.
- [ ] Given either reading is not usable yet, when the summary is shown, then its labeled slot remains and displays a placeholder/status rather than zero.
- [ ] Given the central notch is showing its idle view, including during lock transitions that use that view, when I look at it, then I see only date and time and no CPU/RAM meters.

## Plan

- Add a compact CPU/RAM summary to the Control Center root using the existing readings.
- Keep the CPU and RAM positions stable and preserve a clear placeholder/status for unusable readings.
- Remove CPU/RAM meters from the central idle row while retaining its date and time.
- Keep the existing detailed resource subpage and its navigation unchanged.
- Verify the visible summary values, missing-reading state, and idle center content.

## Out of scope

- Root-filesystem capacity in the summary or detailed view; covered by story 04.
- Additional CPU and memory details; covered by story 03.
- GPU, NPU, network, temperature, or storage-activity metrics.
- Changes to resource polling lifecycle; covered by story 09.
- Changes to the date/time presentation or other center-notch layers.

## Suggestions (your call)

- `ArcMeter` is already used for CPU/RAM in the center idle row and offers a concrete visual pattern for compact resource indicators.

## Size

small
Risk: none

## Log

- L1 request: Load the `flow-pair` skill and follow it. 02
- TDD pause: The unusable-CPU summary test passed immediately against the code from the first green step (`ControlCenterSurface.qml` already renders `Measuring…` instead of zero). Strict TDD requires a failing test before a code change; no test-only commit was made.
- The idle-center test was red with 3 row children and passed after removing both meters (`0964ed2` -> `91ad018`). Focused resource and idle checks pass (4/4).
- `make check` reached the QML suite after 736 unit tests and all prior QML groups passed, but `calendar-open.mjs` failed: it expects the old idle width of 112 px after returning from the calendar, while the date/time-only row now has width 32 px. This pre-existing expectation must change for the accepted layout; paused without modifying it (Strict TDD stop rule 3). `make check-fast` passes.
- Risk: none. Manual visual checks: not run.

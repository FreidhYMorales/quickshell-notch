# Story 08: Show explicit resource statuses

## Story

08. As a user, I want measuring, unavailable, and invalid states shown explicitly in the summary and detail cards so that missing data is never mistaken for zero.

## Acceptance criteria

- [x] Given a compact CPU, RAM, or disk reading is pending, unavailable, invalid, or a valid zero, when I inspect the summary, then it shows `Measuring…`, `Unavailable`, `Invalid reading`, or `0` respectively without moving or hiding the labeled slot.
- [x] Given a detailed reading is pending its first usable sample, its source is absent or unreadable, or its value/sample is malformed, implausible, reset, rolled back, or has an invalid sample interval, when I inspect the resource view, then it shows the matching status and never substitutes zero or a stale value for the bad reading.
- [x] Given a detailed card has both usable and unavailable sub-readings, such as memory with no swap source, when I inspect it, then valid readings remain visible and only the unavailable sub-reading shows `Unavailable`; a legitimate zero remains numeric.

## Plan

- Distinguish first-sample/baseline states from absent or unreadable sources and from malformed or untrustworthy readings.
- Carry each reading's status through the resource data model without reusing stale values after invalid samples.
- Render the matching status in compact summary slots and detailed readings while preserving valid sibling values.
- Cover status classification and rendering for valid zero, measuring, unavailable, and invalid cases.

## Out of scope

- Adding metrics or hardware sources, including GPU, NPU, and temperature telemetry.
- Changing polling lifecycle, monitor ownership, or sampling intervals.
- Changing the summary layout or the resource-grid navigation and scrolling behavior.

## Suggestions (your call)

- `SysInfo.qml` currently reports several parser failures as `unavailable`, while `ControlCenterSurface.detailStatus()` maps every state other than `unavailable` to `Measuring…`. Consider carrying explicit per-reading statuses from acquisition through rendering so invalid data is not confused with a missing source or a pending sample.

## Size

normal
Risk: item 3 (SysInfo status contract consumed by Control Center)

## Log

- L1 request: okay, vamos con la siguiente historia
- Assumption for approval: `Measuring…` means no usable first/baseline sample yet; `Unavailable` means the source is absent or unreadable; `Invalid reading` means a present reading/sample is malformed, implausible, or cannot be trusted (including counter reset/rollback). A valid numeric zero remains `0`.
- Approved by user.
- User resolved the plan mismatch: malformed or untrustworthy counters, resets/rollbacks, and invalid sample intervals show `Invalid reading`; missing/unreadable sources show `Unavailable`; waiting for the first valid baseline remains `Measuring…`. The plan was updated to match.
- Implemented status classification and compact summary rendering: `28cf978` → `b70d41a`, `303b858` → `8fda564`.
- Implemented detailed status rendering and source-status propagation, including optional swap classification: `1ca0698` → `4239053`, `7a62ef4` → `0943394`.
- Focused resource probes passed (22/22); `make check-fast` passed.
- Initial full `make check` exposed tray-menu probe failures; their isolation and menu-loading sizing fixes are recorded below.
- Risk: item 3 (SysInfo status contract consumed by Control Center).
- User requested investigation of the tray failures. Makefile changes `fb2d714` and `368795f` isolate tray menu probes, including the short/long size cases, because they drive shared Wayland input.
- Fixed the tray's delayed menu sizing in `340a48e`; both short- and long-menu size probes pass without changing their assertions.
- The existing memory-details visual probe exposed a legacy fixture with values but no status fields. Updated the renderer to preserve finite legacy memory/swap values when status is omitted (`0d53937`); `controlcenter-memory-details.mjs` passes.
- Calendar focus probe depended on the host MPRIS player's disabled previous control. Updated it in `d29f656` to verify the first focusable media control; `calendar-open.mjs` passes.
- High-risk review found `parseCpu` accepted negative `/proc/stat` counters. Added a red regression test and fix: `5cc0972` → `2a5c910`; `node --test tests/sysStats.test.mjs` passes (17/17).
- Final `make check` passed on `2a5c910`: 770 unit tests passed, all QML probes passed (including calendar and resource-status probes), and smoke ended with `smoke: config loaded`.
- High-risk verifier recheck: `NEEDS DECISION`. It confirmed all acceptance criteria and TDD evidence, but did not independently run `make check` because it was instructed not to start tests. User accepted the successful `make check` run from this session as the verification evidence for closure. Ref comparison showed no refs moved.
- Risk: item 3 (SysInfo status contract consumed by Control Center).

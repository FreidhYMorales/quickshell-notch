# Story 03: CPU and memory details

## Story

03. As a user troubleshooting performance, I want CPU core count, load averages, memory availability, and swap details so that I can understand resource pressure.

## Acceptance criteria

- [ ] Given the resource view is open, when CPU details are available, then it shows the number of online logical processors and the 1-, 5-, and 15-minute load averages alongside CPU usage.
- [ ] Given the resource view is open, when memory details are available, then it shows used/total and available memory, plus swap used/total, with clear human-readable units.
- [ ] Given a requested CPU or memory detail is still measuring or its source is unavailable, when the resource view is shown, then the detail remains labeled and shows its status instead of a fabricated zero.

## Plan

- Extend the CPU details with online logical processor count and the three standard load averages.
- Extend the memory details with available memory and swap used/total.
- Present the added values in the existing resource view with clear labels and units.
- Keep measuring or unavailable readings explicit instead of substituting zero.
- Verify the parsed details and their presentation with deterministic tests.

## Out of scope

- Physical-core count or CPU topology.
- Root-filesystem capacity, disk activity, network rates, GPU/NPU, or temperature details.
- Polling lifecycle changes; covered by story 09.
- General invalid-reading presentation for every resource; covered by story 08.
- Resource grid layout, bounded scrolling, and keyboard focus behavior; covered by story 07.

## Suggestions (your call)

- The existing `/proc/stat` and `/proc/meminfo` parsers in the system-information service provide a concrete pattern for these Linux readings.

## Size

normal
Risk: none

## Log

- L1 request: okay, porque me interesa mantener limpio el worktree, vamos con la siguiente storie
- Approved test list: parser tests for CPU and memory; separate QML integration steps for CPU and memory; final QML coverage for measuring/unavailable states.
- CPU parser cycle: `e7e5e26` red -> `e056c80` green (`node --test tests/sysStats.test.mjs`, 8/8).
- Memory parser cycle: `c11d271` red -> `7312d06` green (`node --test tests/sysStats.test.mjs`, 9/9).
- CPU detail UI cycle: `c20175d` red -> `f17b3cf` green (`node --test tests/qml/controlcenter-cpu-details.mjs`, 1/1).
- Memory detail UI cycle: `f8b2a56` red -> `50a5139` green (`node --test tests/qml/controlcenter-memory-details.mjs`, 1/1); implementation was reduced to a reusable detail row.
- Missing-source status cycle: `162ce30` red -> `6305a9c` green (`node --test tests/qml/controlcenter-details-status.mjs`, 1/1); service distinguishes measuring from unavailable and the view does not render missing values as zero.
- Focused regression: `node --test tests/qml/controlcenter-details-status.mjs tests/qml/controlcenter-memory-details.mjs tests/qml/controlcenter-cpu-details.mjs tests/sysStats.test.mjs` passed (12/12).
- Formatting authorization: user approved formatting-only changes to the committed parser test to clear `deno fmt --check`; commit `afb6502` formats `shell/logic/sysStats.mjs` and `tests/sysStats.test.mjs` without changing behavior. The focused parser suite passes (9/9).
- Calendar test correction: user authorized changing the committed test expectation; `3f41813` restores the expected expanded week (height 112 with strip) after Esc while hover remains true. Focused `tests/qml/calendar-open.mjs` passes.
- Full verification: `make check` passes after the formatting-only correction `afb6502` and calendar test correction `3f41813`; includes formatting, lint, 738 unit tests, QML test suites, and smoke.
- Risk: none.

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

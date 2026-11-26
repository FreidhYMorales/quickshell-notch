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

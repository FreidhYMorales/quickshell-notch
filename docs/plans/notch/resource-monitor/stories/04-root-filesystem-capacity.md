# Story 04: Show root filesystem capacity

## Story

04. As a user managing disk space, I want root-filesystem used, total, and free capacity in the summary and detail view so that I can see how much space remains.

## Acceptance criteria

- [ ] Given the Control Center summary is visible, when root-filesystem capacity is available, then its stable DISK slot shows the used percentage.
- [ ] Given the resource view is open, when root-filesystem capacity is available, then it shows used, total, and free capacity available to the user in human-readable units.
- [ ] Given root-filesystem capacity has not been measured or cannot be read, when the summary or resource view is shown, then the DISK slot remains labeled and displays a placeholder/status rather than a fabricated value.

## Plan

- Read capacity for the root filesystem and expose its used percentage and used, total, and free values.
- Show the percentage in the compact Control Center summary and the capacity values in the resource view.
- Keep the disk label visible and make missing readings explicit.
- Sample with the fixed-argument `df` query only while at least one Control Center is open; never launch it in smoke mode.
- Verify the capacity calculations, units, and unavailable behavior with deterministic tests.

## Out of scope

- Per-device read/write rates, covered by story 05.
- Network, GPU, NPU, or temperature readings.
- General invalid-reading treatment across all resources, covered by story 08.
- Resource-grid scrolling and focus behavior, covered by story 07.

## Suggestions (your call)

- `SysInfo` already exposes CPU and memory readings to both Control Center views; follow that service-to-summary/detail path for filesystem capacity.

## Size

normal
Risk: none

## Log

- L1 request: pushea, y vamos a seguir con la siguiente storie
- L2: User approved the fixed-argument GNU `df -B1 --output=size,used,avail,pcent /` source, without a shell, only while a Control Center is open and never in smoke mode; `Avail` means space available to the user.
- Parser TDD: `f76df50` red -> `d829b3f` green (10/10); `988a326` red -> `37ba905` green (11/11).
- Available UI TDD: `3aea276` red -> `2af5fe1` green (`tests/qml/controlcenter-disk-capacity.mjs`, 1/1).
- Status UI TDD: `8ab029e` red -> `7f8f625` green (`tests/qml/controlcenter-disk-status.mjs`, 1/1).
- Polling-gating probe `c31416f` is red as expected because no df sample is available yet. Paused before production changes: the test step added 61 lines across two files, exceeding the pair skill's ~50-line step limit. Risk: none.

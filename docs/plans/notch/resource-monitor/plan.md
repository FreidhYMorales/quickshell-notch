# Plan: Control Center resource monitor

- Status: approved
- Mode: solo
- Target: Arch Linux + Hyprland + Quickshell

## Goal

Add an occasional-use system resource monitor to the Control Center. Keep the
central notch focused on date and time, provide a compact entry point in the
Control Center, and open a dedicated expanded view for troubleshooting and
checking system load.

## Scope

### Main Control Center

- Add one compact resource widget using the existing circular-meter visual
  language.
- Show CPU, RAM, and root-filesystem capacity in the summary; show GPU and NPU
  only when usable telemetry is available.
- Keep CPU, RAM, and disk positions stable in the compact summary. If a required
  value is measuring, unavailable, or invalid, show a placeholder and an
  explicit per-resource status rather than a misleading number.
- Activating the widget opens a dedicated resource view, modeled on the
  Control Center notifications view.
- Support pointer and keyboard navigation consistently with other Control
  Center views.
- Remove CPU/RAM meters from `CenterIdle`; the central notch shows only date
  and time. `CenterIdle` is also used during lock transitions, so those meters
  disappear there as well.

### Detailed view

- Use a complete grid of resource cards in a dedicated view. Keep every
  resource in the same view; do not hide resource groups behind tabs.
- Keep the `PanelWindow` fixed-size. Bound its maximum height by the available
  monitor height (with safe margins) and the configured surface maximum; animate
  the inner panel within that bound.
- Put the grid in a clipped, fixed-height viewport inside the inner panel. Use
  vertical scrolling when the grid exceeds the viewport; pointer wheel/drag
  scrolls it, and keyboard focus must bring the focused card into view.
- CPU: aggregate utilization, core/thread count, and load averages when
  available.
- Memory: used/total and available memory; swap used/total when available.
- Storage: root filesystem used/total/free space and read/write throughput
  where the backing device can be identified reliably.
- GPU: utilization derived from available residency counters; report Intel xe
  GTs separately rather than inventing a combined percentage. Frequency may be
  shown as supplementary data when available.
- NPU: utilization derived from `npu_busy_time_us`, plus current/max frequency
  and memory utilization when available.
- Network: aggregate receive/transmit rates, excluding loopback.
- Temperature: useful CPU/GPU thermal readings when exposed without elevated
  privileges; label sensors clearly and do not imply a universal CPU package
  sensor exists.
- No historical graph in v1. Show current values and, where applicable, rates
  computed from consecutive samples.
- Keep every detailed-view card in the grid. Show `Measuring…` until enough
  samples exist, `Unavailable` when a source is absent/unreadable, and
  `Invalid reading` when a value or counter cannot be trusted. Never substitute
  zero for any of these states.

## Availability and sampling

- Track open Control Center instances by monitor name in shared state. Sample
  while at least one instance is open, including its compact resource summary
  and dedicated view; stop polling only after the last instance closes.
- The current `SysInfo` CPU/RAM values are consumed only by `CenterIdle`.
  Remove those meters and gate shared CPU/RAM sampling with Control Center
  visibility.
- Keep hardware-specific GPU, NPU, and temperature sources optional. Missing,
  unreadable, malformed, reset, or implausible counters must yield unavailable
  data, not a fabricated zero or percentage.
- The first counter sample establishes a baseline; rate/utilization values stay
  unavailable until a valid second sample.
- Avoid spawning recurring external processes for telemetry, except root
  filesystem capacity: sample it with GNU `df` only while at least one Control
  Center instance is open, and stop after the last instance closes.
- Smoke mode must not start resource polling.

## UX

### Summary widget

Selected: a compact entry widget in the main Control Center; activation opens
the dedicated expanded resource view. Keep the central notch to date and time.
Keep CPU/RAM/disk slots visible and labeled; replace missing values with a
placeholder plus a short status (`Measuring…`, `Unavailable`, or
`Invalid reading`). Optional GPU/NPU meters remain omitted if unavailable.

```text
╭────────────────────────────╮
│ ◉       ◉       ◉      ◉  ◉│
│CPU     RAM    DISK    GPU NPU│
│12%     48%    71%     6% 24%│
╰────── open resource view ───╯
```

GPU/NPU meters are omitted when unavailable. Network and temperature remain in
the detailed view to keep the summary legible.

### Detailed view

Selected: a complete grid of cards, all supported resources visible together
in a dedicated view modeled on notifications. The inner panel expands within
the fixed, monitor-bounded `PanelWindow`; a clipped viewport scrolls when the
grid exceeds the available height. Cards use the established notch styling,
clear labels, and secondary readings. Cards remain present when a sensor is
unavailable or has not yet produced a valid sample, and display the
corresponding status inline.

```text
╭ Resources ───────────────────────╮
│╭ CPU 12% · load …╮ ╭ RAM 48% … ╮│
│╰ cores · freq …──╯ ╰ swap …────╯│
│╭ DISK 71% · …────╮ ╭ NET ↓/↑ … ╮│
│╰ read/write …────╯ ╰────────────╯│
│╭ GPU GT0/GT1 …───╮ ╭ NPU 24% … ╮│
│╰ freq …──────────╯ ╰ memory …───╯│
│╭ TEMPERATURES · CPU/GPU …────────╮│
│╰─────────────────────────────────╯│
╰───────────────────────────────────╯
```

## Out of scope

- Persistent background polling while the Control Center is closed.
- Historical charts, alerts, thresholds, or logging.
- Process-by-process usage, per-network-interface controls, and device
  management.
- Requiring root, installing a daemon, or adding a dependency.
- Guaranteeing identical GPU/NPU/temperature metrics across hardware vendors.

## Acceptance criteria

1. The main Control Center shows a compact resource summary without changing
   idle layout. CPU/RAM/disk retain labeled slots with explicit placeholder
   states when values are unavailable or invalid; unavailable optional hardware
   meters are omitted.
2. The central notch shows only date and time; CPU/RAM meters are removed from
   `CenterIdle`.
3. Activating the Control Center entry opens a keyboard- and pointer-accessible
   dedicated resource view with a complete grid inside a fixed-size,
   monitor-bounded viewport; keyboard focus remains visible while scrolling,
   and Escape/back returns to the Control Center root.
4. CPU, RAM, root-filesystem capacity, network rates, and available temperature
   readings are represented without requiring optional accelerator hardware.
5. Detailed-view cards distinguish measuring, unavailable, and invalid
   readings; no unavailable or invalid metric is shown as zero.
6. GPU/NPU readings appear only when their data sources are valid; derived
   percentages/rates handle initial samples, counter rollback, malformed data,
   and missing files without false values.
7. Sampling remains active while any monitor's Control Center is open, stops
   only after the last instance closes, and is disabled in smoke mode.
8. Unit tests cover parsers, deltas, resets, unavailable sources, and optional
   data; lifecycle tests cover two monitors opening and closing independently;
   QML probes cover navigation and unavailable devices.
9. Unit tests verify root-mount capacity and correct rate units; counter
   rollback or invalid elapsed time yields unavailable rates.
10. `make check` passes.

## Implementation notes

- Keep parsing and counter math in pure `shell/logic/*.mjs`; services own data
  acquisition and lifecycle; QML renders the values.
- Reuse `SysInfo`'s `/proc/stat` and `/proc/meminfo` parsing where practical;
  no other runtime consumer currently reads its CPU/RAM properties.
- Root filesystem capacity describes `/`, not raw device activity. Query it
  with GNU coreutils `df -B1 --output=size,used,avail,pcent /`, passing fixed
  arguments directly to Quickshell `Process` (never through a shell). Parse the
  numeric data row without depending on localized column headings. Present
  `avail` as free space available to the user. This is the only recurring
  external telemetry process allowed; sample only while at least one Control
  Center is open, stop after the last closes, and never start it in smoke mode.
- Normalize network/disk activity-counter deltas by elapsed time and reject
  resets, counter rollback, and non-positive elapsed intervals.
- Keep the outer `PanelWindow` fixed-size. Compute a monitor-bounded maximum
  height using safe margins and the configured surface maximum; animate the
  inner panel and scroll only inside the fixed viewport. Keep the input mask
  aligned with the drawn body and preserve pointer-close behavior.
- Add new QML components to the appropriate `qmldir` and centralize new labels,
  timings, and dimensions in `shell/config/`.

## Plan-review resolutions

| Finding | Resolution | Decided by |
|---|---|---|
| Review 1: `SysInfo` samples while closed and may have other consumers | Repository inventory found only `CenterIdle` reads CPU/RAM, including its lock-transition instance. Remove the meters from `CenterIdle` and gate sampling on Control Center visibility. | User (central notch date/time only); planner (consumer inventory and lifecycle) |
| Review 1, finding 2: fixed Control Center bounds and unspecified scrolling | Use a dedicated complete grid inside a clipped viewport; scroll with pointer input and keep keyboard-focused cards visible. | User (complete dedicated grid); planner (bounded viewport behavior) |
| Review 3: loading and failed-read presentation | Keep every detail card in the grid and show `Measuring…`, `Unavailable`, or `Invalid reading` inline; never substitute zero. | User |
| Review 4: root filesystem and counter semantics | Define capacity as `/`; normalize rates by elapsed time and treat reset/rollback/invalid elapsed time as unavailable. Add unit-test coverage. | Planner |
| Review 2, finding 1: viewport geometry conflicts with fixed `PanelWindow` | Keep `PanelWindow` fixed-size and monitor-bounded; animate the inner panel inside its configured maximum and scroll the complete grid within a clipped viewport. Preserve mask alignment and pointer-close behavior; keyboard focus scrolls into view. | Planner |
| Review 2, finding 2: compact-summary failure states | Keep CPU/RAM/disk positions and labels stable; replace invalid/missing values with a placeholder plus an explicit per-resource status. Omit unavailable optional GPU/NPU meters. | User |
| Review 3, finding 1: concurrent Control Centers on multiple monitors | Track open state by monitor name in shared service state. Poll while any instance is open; stop only when the registry is empty. Test two open monitors and closing either one. | Planner |

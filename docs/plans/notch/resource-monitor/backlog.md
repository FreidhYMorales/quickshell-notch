# Backlog: Control Center resource monitor

## Context

- What: An on-demand system resource monitor in the Quickshell notch Control Center. Plan: `docs/plans/notch/resource-monitor/plan.md`.
- Stack: QML + Quickshell 0.3, pure `.mjs` logic, no new dependencies.
- Expensive decisions: Fixed-size, monitor-bounded `PanelWindow` with a clipped scrollable resource grid; polling remains active while any monitor's Control Center is open, tracked by monitor name.
- Test command: `make check`
- Single test: `node --test tests/sysStats.test.mjs`

## Backlog

01. [x] 7392ca6 As a Control Center user, I want to open the resource view and see current CPU and RAM usage so that I can inspect system load at a glance.
02. [x] 91ad018 As a Control Center user, I want a compact CPU/RAM summary and a central notch that shows only date and time so that resource details stay in the Control Center. Requires: #01
03. [x] 6305a9c As a user troubleshooting performance, I want CPU core count, load averages, memory availability, and swap details so that I can understand resource pressure. Requires: #01
04. [x] 24c2d1b As a user managing disk space, I want root-filesystem used, total, and free capacity in the summary and detail view so that I can see how much space remains. Requires: #01
05. [x] 305e392 As a user troubleshooting storage, I want read/write rates when the backing device can be identified reliably so that I can see current disk activity. Requires: #04
06. [x] 35eb15b As a user troubleshooting connectivity, I want aggregate network receive/transmit rates excluding loopback so that I can see current network activity. Requires: #01
07. [x] 29ee45c As a user inspecting resources, I want a complete keyboard- and pointer-accessible grid in a monitor-bounded viewport so that every resource remains reachable. Requires: #01
08. [ ] As a user, I want measuring, unavailable, and invalid states shown explicitly in the summary and detail cards so that missing data is never mistaken for zero. Requires: #02, #03, #04
09. [ ] As a user, I want polling active while any monitor's Control Center is open, stopped after the last closes, and disabled in smoke mode so that telemetry stays current without continuous background polling. Requires: #01
10. [ ] As an Intel GPU user, I want available GPU utilization and frequency shown per GT so that I can inspect accelerator activity. Requires: #01, #09
11. [ ] As an Intel NPU user, I want available NPU utilization, frequency, and memory readings so that I can inspect NPU activity. Requires: #01, #09
12. [ ] As a user diagnosing thermal issues, I want clearly labeled CPU/GPU temperatures when exposed so that I can inspect available thermal readings. Requires: #01, #09

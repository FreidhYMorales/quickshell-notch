# Story 09: Poll resources only while the Control Center is open

## Story

09. As a user, I want polling active while any monitor's Control Center is open, stopped after the last closes, and disabled in smoke mode so that telemetry stays current without continuous background polling.

## Acceptance criteria

- [x] Given one or more Control Centers are open on any monitors, when I inspect the resource summary or view, then telemetry continues updating while at least one remains open.
- [x] Given multiple monitors have their Control Centers open, when one closes, then polling continues for the remaining open Control Center; when the last closes, then resource polling stops.
- [x] Given the shell runs in smoke mode, when it starts or opens a Control Center, then resource polling does not start.

## Plan

- Make resource sampling follow shared Control Center visibility across monitors.
- Start sampling when the first Control Center opens and stop it when the last closes.
- Keep smoke runs free of resource polling.
- Verify independent monitor open/close sequences and smoke-mode behavior.

## Out of scope

- Adding telemetry sources, changing sampling intervals, or changing resource presentation.
- Polling resources while every Control Center is closed.

## Suggestions (your call)

- `SysInfo` currently gates disk and network sampling on the open-monitor registry, but its CPU, memory, and load-average timer runs whenever smoke mode is off. The registry already receives open/close events from each Control Center.

## Size

normal
Risk: item 4 (shared polling lifecycle across monitors)

## Log

- L1 request: okay, sigamos con ls historias
- Assumption for approval: when the last Control Center closes, readings that depend on counter baselines are discarded; reopening starts a fresh baseline and shows `Measuring…` until a valid sample is available.
- Implemented first-open gated sampling and reset CPU/disk/network counter baselines: `28d9d26` → `f27dc5b`.
- Added a two-monitor lifecycle probe and injectable CPU-stat source: `d7f1af8` → `a3f9b2c`. The probe verifies polling continues after one monitor closes and stops after the last.
- Smoke-mode coverage passed on the existing guard: `87b272d`.
- `make check` passed on `87b272d`: 770 Node tests passed, all QML probes passed, and smoke ended with `smoke: config loaded`.
- High-risk verifier: PASS for all three criteria and TDD evidence. It used the supplied `make check` result and did not rerun the command. Ref comparison showed no refs moved.
- Risk: item 4 (shared polling lifecycle across monitors).

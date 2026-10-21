# System Status Services Specification

## Purpose

Data contract for `SysInfo`, `Time` and `Recorder`, reused from the old config.

## Requirements

### Requirement: SysInfo

`SysInfo` MUST expose `cpu` and `ram` as percentages 0-100 and MUST keep the reused polling cadence; no new polls MAY be added.

#### Scenario: Values in range (manual)
- GIVEN the shell is running
- WHEN `cpu` and `ram` are read
- THEN both are within 0-100

### Requirement: Time

`Time` MUST expose the current minute-precision clock and `dayKey` (`YYYY-MM-DD`, produced by the pure calendar rule `dayKey`), updating at least each minute. It MUST emit `dayChanged` when `dayKey` changes, which happens at local midnight. Date and time text MUST be produced by pure formatters, independent of locale. The clock is 24-hour. Month names come from the `Strings` token:
`shortDate(3, 20, months) = "Mar 20"`, `shortDate(1, 5, months) = "Jan 5"`, `clock(14, 32) = "14:32"`, `clock(9, 5) = "09:05"`.

#### Scenario: Midnight rollover
- GIVEN `Time.dayKey` is 2026-03-20 before local midnight
- WHEN the minute tick crosses into 2026-03-21
- THEN `dayChanged` is emitted once AND `dayKey` reads 2026-03-21 (no `msUntilMidnight` timer exists; the `dayKey` change drives the rollover)

#### Scenario: Locale independent
- GIVEN the system locale is not English
- WHEN `shortDate` runs for month 3, day 20 with the caller's month names
- THEN the result is "Mar 20"

### Requirement: Recorder

`Recorder.recording` MUST be a boolean reflecting whether a recording is active, and `Recorder.setRecording(on)` MUST set it. In this change the Recorder is minimal; the full recorder port is DEFERRED to `notch-control-center`.

#### Scenario: Toggle (manual)
- GIVEN recording starts then stops
- WHEN `recording` is observed
- THEN it is true then false

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

`Time` MUST expose the current date-time, updating at least each minute, and MUST emit a day-change signal at local midnight. Date and time text MUST be produced by pure formatters, independent of locale:
`formatDate(2026-03-20) = "Mar 20"`, `formatTime(14:32) = "14:32"`, `formatTime(09:05) = "09:05"`, `formatDate(2026-01-05) = "Jan 5"`.

#### Scenario: Midnight
- GIVEN 2026-03-20 23:59:30 local
- WHEN `msUntilMidnight` is computed
- THEN it returns 30000

#### Scenario: Locale independent
- GIVEN the system locale is not English
- WHEN `formatDate` runs for 2026-03-20
- THEN the result is "Mar 20"

### Requirement: Recorder

`Recorder.recording` MUST be a boolean reflecting whether a recording is active.

#### Scenario: Toggle (manual)
- GIVEN recording starts then stops
- WHEN `recording` is observed
- THEN it is true then false

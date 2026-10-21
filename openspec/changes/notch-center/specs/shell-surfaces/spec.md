# Delta for Shell Surfaces

## MODIFIED Requirements

### Requirement: Idle centre content

The idle centre notch MUST be pure `#000` and show live content as defined in `center-idle-view` (date, time, CPU/RAM rings, overlays, battery layers), with every colour, timing and string taken from tokens.
(Previously: static placeholder text from the strings token, with no data bindings.)

#### Scenario: Idle
- GIVEN no events
- WHEN the shell is running
- THEN the centre shows live date, time and rings on black on every monitor

#### Scenario: Smoke (manual)
- GIVEN `NOTCH_SMOKE=1`
- WHEN `make smoke` runs
- THEN the idle content loads without errors

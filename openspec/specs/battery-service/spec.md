# Battery Service Specification

## Purpose

UPower-backed battery data plus the pure logic that classifies it into display layers and fires the one-shot critical event. Logic lives in `shell/logic/` (no Quickshell imports).

## Requirements

### Requirement: Battery state exposure

The `Battery` service MUST expose `present`, `plugged`, `charging`, `full`, `percentage` (integer 0-100) and a `pluggedIn` edge signal. `plugged` MUST be derived from `UPower.onBattery` (true when unplugged) and the display device state: it is true when `onBattery` is false, or when the state is `charging`, `full` or `pending-charge`. `percentage` MUST be the UPower 0-1 fraction rounded to an integer and clamped to 0-100. It MUST NOT poll.

#### Scenario: No battery
- GIVEN a desktop without a battery device
- WHEN the service loads
- THEN `present` is false AND no battery layer is ever requested

#### Scenario: Plug-in edge
- GIVEN `plugged` is false
- WHEN line power connects
- THEN `plugged` becomes true AND `pluggedIn` is emitted exactly once

### Requirement: Layer classification

A pure function `classify({present, plugged, charging, full, percentage}, {low})` MUST return one layer: `none`, `charging`, `plugged`, `full` or `low`. `plugged` means on line power but not charging (for example held at a charge limit). The `low` threshold comes from the `Limits.batteryLow` token (20).

| present | plugged | charging | full | pct | layer |
|---|---|---|---|---|---|
| false | any | any | any | any | none |
| true | true | true | false | 72 | charging |
| true | true | false | true | 100 | full |
| true | false | false | false | 19 | low |
| true | false | false | false | 20 | none |
| true | false | false | false | 80 | none |
| true | true | true | false | 5 | charging |
| true | true | false | false | 80 | plugged |

#### Scenario: Boundary 19 vs 20
- GIVEN unplugged at 19% and then at 20%
- WHEN classified
- THEN the results are `low` and `none`

#### Scenario: Plug replaces low
- GIVEN unplugged at 18% (`low`)
- WHEN `plugged` and `charging` become true
- THEN the result is `charging`

### Requirement: One-shot critical event

A pure reducer `criticalStep(state{armed}, {present, plugged, percentage}, {critical})` MUST return `{fire, armed}`, with `critical` taken from `Limits.batteryCritical` (10). It MUST fire once when unplugged and `percentage <= critical` while armed, disarm, and re-arm only when `plugged` becomes true. It MUST NOT depend on the centre notch state reducer.

**DEFERRED to `notch-notifications`**: when the shell starts at or below the critical limit, the event is not fired, because the store attaches its listener after the first battery refresh. This gap is known and accepted for this change.

#### Scenario: Fires once
- GIVEN armed, unplugged, 11%
- WHEN percentage goes 10 then 9 then 8
- THEN `fire` is true only at 10 AND false for 9 and 8

#### Scenario: Re-arm on plug-in
- GIVEN fired and disarmed at 9%
- WHEN plugged becomes true, then unplugged at 10%
- THEN `fire` is true again

#### Scenario: Plugged never fires
- GIVEN armed and plugged at 5%
- WHEN stepped
- THEN `fire` is false

### Requirement: Dev override

A battery override (dev flag `Flags.batteryOverride`) SHOULD let a developer force the inputs of `classify` through `applyOverride(input, override)`, so layers can be exercised on machines without a battery. A null field keeps the real input.

#### Scenario: Override (manual)
- GIVEN override set to unplugged 18%
- WHEN the idle notch is shown
- THEN the low layer appears

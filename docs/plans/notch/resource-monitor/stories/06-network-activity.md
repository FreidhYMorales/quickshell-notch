# Story 06: Show network activity

## Story

06. As a user troubleshooting connectivity, I want aggregate network receive/transmit rates excluding loopback so that I can see current network activity.

## Acceptance criteria

- [ ] Given the resource view is open and two valid network samples are available, when I inspect the network card, then it shows aggregate receive and transmit rates for non-loopback interfaces in clear human-readable units.
- [ ] Given only the initial sample is available or network counters cannot be read or trusted, when I inspect the network card, then it shows the appropriate measuring or unavailable status instead of zero or a misleading rate.
- [ ] Given an interface counter resets or rolls back, or the sample interval is invalid, when rates are calculated, then the affected rates are unavailable rather than misleading.

## Plan

- Read aggregate network counters while the resource monitor is active, excluding loopback.
- Derive receive and transmit rates from consecutive valid samples and elapsed time.
- Show both rates in the network card with clear labels, units, and explicit status.
- Verify aggregation, loopback exclusion, rate calculation, and unusable samples with deterministic tests.

## Out of scope

- Per-interface rates, controls, or selection.
- Historical graphs, alerts, or persistent polling while the Control Center is closed.
- General polling lifecycle changes, covered by story 09.
- Resource-grid scrolling and focus behavior, covered by story 07.

## Suggestions (your call)

- The approved plan calls for rates computed from consecutive samples and for resets, counter rollback, and non-positive elapsed intervals to produce unavailable rates.

## Size

normal
Risk: item 4 (shared resource sampling state)

## Log

- L1 request: Load the `flow-story` skill and follow it. 06
- Approved by user.
- Approved test list: aggregate receive/transmit rates excluding loopback (unit); unusable samples, resets, rollback, and invalid intervals (unit); network values and pending/unavailable states render in the resource view (QML integration).
- Network aggregation cycle: `adf206a` red (`SysStats.parseNetworkActivity is not a function`) → `294f726` green (`node --test tests/sysStats.test.mjs`, 14/14). The expected rates were 250 B/s receive and 350 B/s transmit, excluding the large loopback delta.
- Unusable-sample characterization: passed on first run because the parser already rejects missing, malformed, reset, and invalid-interval samples; no production change was needed. Commit `5c36614`; focused suite 15/15.
- QML integration red: `bf40113` fails at the rate-value assertion. The fixture expects `2 KiB/s`, while the existing formatter renders 2048 bytes/s as `2.0 KiB/s`. Stopped before changing the committed test; Risk: item 4 (shared resource sampling state).
- User authorized correcting the committed fixture expectation to `2.0 KiB/s` (`c7cf041`); the QML probe then passed 1/1. Presentation commit `f338b85` adds receive/transmit rows and explicit statuses. Service sampling remains to be connected and tested.
- Network polling test red: `99f2c30` fails because its fixture opens the Control Center root view, so the resource-rate labels are absent. A standalone diagnostic confirmed `SysInfo` reaches `available` with both rates at 0 from the fixed fixture. This is a test setup failure, not valid red; stopped under stop rule 3 before editing the committed fixture. The parser formatting check also required `deno fmt shell/logic/sysStats.mjs`; both formatting and `SysInfo.qml` changes remain uncommitted.

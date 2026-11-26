# Plan review: Control Center resource monitor
Verdict: PASS WITH CHANGES
Summary: The plan has a clear scope and appropriate safeguards for optional telemetry, but its sampling lifecycle conflicts with the existing always-running `SysInfo` service. The detail view also needs an explicit bounded scrolling strategy for the fixed-size Control Center surface.

## Findings
| # | Category | Severity (blocker/major/minor) | Finding | Evidence | Suggested fix |
|---|---|---|---|---|---|
| 1 | Contradiction / lifecycle | major | “Only sample while the Control Center is open” and “stop polling when it closes” conflict with reusing `SysInfo` as written: its timer runs whenever smoke mode is off, regardless of whether the Control Center is open. Reusing it unchanged means CPU/RAM continue polling while closed; stopping it could affect other consumers. | Plan §Availability and sampling, lines 45–55; `shell/services/SysInfo.qml:18–26` | Decide whether `SysInfo` remains a shared background service or becomes demand-driven. If demand-driven, define how the Control Center activates/deactivates it and account for any other consumers. |
| 2 | Gap / UX feasibility | major | The detail view is specified as one scrollable list, but the existing Control Center sizes its panel from content height and passes that to a corner layout bounded by the surface’s fixed maximum dimensions. The plan does not say how scrolling is implemented or how content remains reachable when cards exceed the available height. | Plan §Detailed view, lines 25–43, 76–81; `ControlCenterSurface.qml:29–36, 194–200` | Specify the viewport height and scrolling/input behavior within the existing surface bounds; include keyboard scroll access and verify the detail view fits small screens. |
| 3 | Gap / states | minor | The plan does not define user-visible loading or error behavior for the summary or detail view. The first-sample rule says derived values are unavailable, but it does not say whether that appears as a placeholder, omitted meter, or error; similarly, failures in required CPU/RAM/storage sources have no stated display policy. | Plan §Availability and sampling, lines 45–55; §Acceptance criteria, lines 109–124 | State how “sampling,” unavailable required metrics, and failed reads render, while retaining the existing no-fabricated-zero rule. |
| 4 | Technical correctness | minor | The plan leaves filesystem capacity and storage/network throughput acquisition APIs and counter semantics for implementation. It does require API validation, but does not explicitly require validating counter units, wrap/reset handling, or whether filesystem capacity is for the root mount rather than a device. | Plan §Detailed view, lines 25–43; §Implementation notes, lines 127–136 | Add acceptance coverage for root-mount capacity and rate-counter units/reset behavior; verify APIs and sources before choosing them. |

## Scope vs deadline
| Item | Est. dev-days | Cut (MUST/SHOULD/LATER) |
|---|---:|---|
| CPU/RAM data reuse, additional parsers and tests | 1–2 | MUST |
| Summary widget, navigation, and unavailable/loading rendering | 1–2 | MUST |
| Detail view, bounded scrolling, keyboard/pointer behavior | 2–3 | MUST |
| Storage capacity and network rates | 1–2 | MUST |
| Optional GPU/NPU/temperature telemetry and graceful degradation | 2–3 | SHOULD |
| Lifecycle/smoke-mode probes and integration verification | 1–2 | MUST |
| **Total** | **8–14** | |

Total MUST: **6–11 dev-days vs available: no deadline specified** -> **fits** (no deadline constraint given; effort estimate is approximate).

## Unnamed risks
- SysInfo may have consumers outside the Control Center, so changing its polling lifecycle could silently stale their data — medium likelihood — inventory consumers and define shared-service behavior before implementation.
- The detail content may exceed the fixed Control Center surface, especially on smaller displays — medium likelihood — test the longest supported card set and constrained screen sizes early.
- Available sysfs/procfs metrics and device-counter layouts may differ across machines — medium likelihood — test missing and malformed sources on the target host and ensure optional cards degrade cleanly.

## Questions for the user (max 5)
1. Should CPU/RAM polling continue for any other consumers when the Control Center is closed, or should the monitor be the sole trigger? — This determines whether the existing shared `SysInfo` timer can be gated — recommendation: inventory consumers and preserve their needs before gating polling.

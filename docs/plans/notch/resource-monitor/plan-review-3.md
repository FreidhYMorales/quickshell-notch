# Plan review: Control Center resource monitor
Verdict: PASS WITH CHANGES
Summary: The plan addresses the previous reviews’ main concerns: constrained scrolling, compact-summary failure states, root-filesystem semantics, and counter resets. One lifecycle gap remains: the app targets all monitors, but the plan does not define polling behavior if Control Centers are open on multiple monitors at once.

## Findings
| # | Category | Severity (blocker/major/minor) | Finding | Evidence | Suggested fix |
|---|---|---|---|---|---|
| 1 | Gap / concurrency | minor | Sampling is gated by Control Center visibility, but the target supports all monitors and each Control Center surface is per-monitor. The plan does not specify whether polling stays active while *any* instance is open, or how closing one instance affects another that remains open. | Plan §Availability and sampling; `AGENTS.md` §Platforms; `ControlCenterSurface.qml:18–19, 123–137` | Define the shared service lifecycle as active while at least one Control Center instance is open; verify opening on two monitors and closing either one. |

## Scope vs deadline
| Item | Est. dev-days | Cut (MUST/SHOULD/LATER) |
|---|---:|---|
| CPU/RAM data reuse, additional parsers, and tests | 1–2 | MUST |
| Summary widget, navigation, and status rendering | 1–2 | MUST |
| Detailed view, bounded scrolling, keyboard/pointer behavior | 2–3 | MUST |
| Storage capacity and network rates | 1–2 | MUST |
| Optional GPU/NPU/temperature telemetry and graceful degradation | 2–3 | SHOULD |
| Lifecycle/smoke-mode probes and integration verification | 1–2 | MUST |

Total MUST: 6–11 dev-days vs available: no deadline specified -> fits

## Unnamed risks
- Multiple monitor surfaces may disagree about whether shared polling should run — medium likelihood — make polling active while any Control Center is open and test overlapping lifecycles.

## Questions for the user (max 5)
1. None.

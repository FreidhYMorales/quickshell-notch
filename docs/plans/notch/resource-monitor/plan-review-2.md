# Plan review: Control Center resource monitor
Verdict: PASS WITH CHANGES
Summary: The second revision resolves the prior review’s four findings: CPU/RAM sampling is tied to Control Center visibility, constrained-view scrolling and input are specified, unavailable/invalid states are defined, and root-mount/rate semantics have test coverage. One significant feasibility conflict remains: the plan proposes expanding the view, while the existing surface is fixed-size and the repo explicitly requires fixed-size `PanelWindow`s.

## Findings
| # | Category | Severity (blocker/major/minor) | Finding | Evidence | Suggested fix |
|---|---|---|---|---|---|
| 1 | Technical correctness / UX feasibility | major | The plan says the detailed view expands to fit, then scrolls when it cannot fit, but does not explain how that works within the existing fixed-size surface. `ControlCenterSurface` computes content size against `root.implicitWidth` and `root.implicitHeight`; `AGENTS.md` says every `PanelWindow` is fixed-size and animates inside. Without a defined bounded viewport and layout behavior, content may be clipped before scrolling can make it reachable. | Plan §Detailed view, lines 32–37, 94–99; `shell/notches/controlcenter/ControlCenterSurface.qml:29–36, 194–200`; `AGENTS.md:42` | Specify the maximum viewport dimensions within the existing surface and how the expanded view remains inside them; keep scrolling inside that viewport and verify keyboard and pointer access on constrained displays. |
| 2 | Gap / failure states | minor | Detailed cards have explicit measuring, unavailable, and invalid states, but the compact summary does not define what to show if required CPU, RAM, or root-filesystem data is unreadable or invalid. The plan says those metrics appear in the summary; only optional GPU/NPU meters are explicitly omitted when unavailable. | Plan §Scope, lines 18–23; §Summary widget, lines 76–90; §Detailed view, lines 54–57 | Define compact-summary behavior for unavailable required metrics, such as inline status text or an omitted meter with an accessible indication. |

## Scope vs deadline
| Item | Est. dev-days | Cut (MUST/SHOULD/LATER) |
|---|---:|---|
| CPU/RAM data reuse, additional parsers, and tests | 1–2 | MUST |
| Summary widget, navigation, and status rendering | 1–2 | MUST |
| Detailed view, bounded scrolling, keyboard/pointer behavior | 2–3 | MUST |
| Storage capacity and network rates | 1–2 | MUST |
| Optional GPU/NPU/temperature telemetry and graceful degradation | 2–3 | SHOULD |
| Lifecycle/smoke-mode probes and integration verification | 1–2 | MUST |
| **Total** | **8–14** | |
Total MUST: **6–11 dev-days vs available: no deadline specified** -> fits

## Unnamed risks
- Hardware telemetry layouts and exposed sensors may vary across the target machine and other monitors’ environments — medium likelihood — test absent, unreadable, malformed, and unsupported sources; keep optional data graceful.
- Expanding or scrolling the dedicated view may interact poorly with the existing surface mask and pointer-close behavior — medium likelihood — prototype the bounded viewport early and verify navigation at the panel edges.

## Questions for the user (max 5)
1. None. Prior review’s user decision about the central notch is recorded; remaining issues can be resolved technically within the plan.

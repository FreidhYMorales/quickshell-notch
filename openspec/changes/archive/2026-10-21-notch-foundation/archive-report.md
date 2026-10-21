# Archive report: notch-foundation

**Date**: 2026-10-21
**Project**: quickshell-notch (engram project "quickshell notch")
**Artifact store**: openspec (engram archive report saved as `sdd/notch-foundation/archive-report`)
**Verdict at verify**: PASS WITH WARNINGS (0 CRITICAL, 4 WARNING, 3 SUGGESTION)
**Outcome**: Archived. Delta specs merged into `openspec/specs/`. Status: closed, no follow-up change required by this archive.

## Observation IDs read (engram traceability)

| Artifact | Engram topic key | Observation ID |
|---|---|---|
| proposal | `sdd/notch-foundation/proposal` | #606 |
| spec | `sdd/notch-foundation/spec` | #607 |
| design | `sdd/notch-foundation/design` | #608 |
| tasks | `sdd/notch-foundation/tasks` | #610 |
| verify-report | `sdd/notch-foundation/verify-report` | #617 |

Full content was read with `mem_get_observation` for each ID. The openspec files in this folder are the authoritative copies; the observations are the engram mirror.

## Final state at close

Final-state facts are ranked per the sdd-archive Final-State Authority section: repository evidence first, then the tasks artifact, then the launch-prompt facts, then the verify-report snapshot.

- **Code on main**: HEAD is `e0b9406` (`docs(sdd): verify notch-foundation`), verified with `git log`. The implementation landed as commits `f2b0b6b` through `58d16e5`. Commit `58d16e5` (`fix(geometry): concave ears and compact idle notch`) is the post-apply fix: concave ears, `Layout.idleWidth` (260), and `cornerRadius` (18).
- **Tests**: `node --test tests/` at archive time reports 108 pass, 0 fail. This supersedes the verify-time count, which was also 108.
- **Tasks**: `tasks.md` contains 28 checkboxes, all checked (`[x]`), and zero unchecked. The verify-report line "All 24 tasks (1.1-6.3)" is a miscount. The tasks artifact is authoritative: 28 tasks, 6 phases.
- **Chain**: the work shipped as stacked PRs to main (chain strategy `stacked-to-main`). The apply phase recorded 8 PRs including splits 2a/2b and 4a/4b. The later post-apply fix is recorded as PR #9 in the launch facts.

## Verify-report items at close (snapshot, rank 4)

Per `verify-report` #617 at verification time:

- **W1 (accepted, deferred)**: the spec scenarios "Queue order (+1)" and "toast stays queued" are not implemented. The toast queue and `+N` counter belong to the `notch-notifications` change, which rewrites the `Notifs` service. The reducer keeps a single toast slot in which the newest toast is shown, and suppressed toasts only set `blinkDot`. Both scenarios are kept in the main spec and marked `[DEFERRED to notch-notifications]`. They are not deleted.
- **W2 (accepted per ADR 0003)**: Session and Hypr QML behaviour has no committed repeatable test. Only `shell/logic` is unit-tested; QML is covered by smoke plus manual checks.
- **W3 (manual)**: twelve scenarios are manual-only. The user confirmed concave ears, bottom corner radius, click-through, and hover runtime (no errors in the log), per the verify-report Resolutions section.
- **W4 (accepted per ADR 0003)**: tasks 4.5-4.6 and 5.x-6.x have no test-first evidence, because QML is not unit-testable under the project convention.
- **Suggestions, open**: S1 static test for `hl.dsp` and `Visibilities` greps and the literal scan; S2 light-scheme palette fixture (the "Light mode" scenario is therefore PARTIAL); S3 defensive uncovered branch in `centerState.mjs`.
- **Manual checks still pending** (no second monitor available at verify time, per the verify-report Resolutions): monitor hot-plug, multi-monitor reserved strip and surface set, `showPlaceholders` visuals, per-wallpaper palette with real matugen output. These are not verified by this archive and remain for a later phase.

## Spec sync

Main specs were created under `openspec/specs/` because it was empty. Each was produced by a mechanical `cp` from the delta spec, followed by a `diff -r` readback that was empty. The vocabulary reconciliation was then applied with exact-match scripted replacements. The reconciled differences are intentional and are listed below.

| Capability | Requirements | Scenarios | Action |
|---|---|---|---|
| center-notch-state | 13 | 25 | Created. Vocabulary reconciled (design wins); "Queue order (+1)" and the "toast stays queued" clause deferred to `notch-notifications`; "Owner change does not move" reconciled per tasks.md. |
| shell-surfaces | 7 | 11 | Created. Smoke requirement notes that only the spacer zone is gated in this change. |
| visual-tokens | 4 | 7 | Created. Layout requirement notes `idleWidth` (260) and `cornerRadius` (18). |
| session-service | 4 | 4 | Created, unchanged from delta. |
| hypr-dispatch | 3 | 4 | Created, unchanged from delta. |

Totals: 31 requirements, 51 scenarios. These match the verify-report envelope.

Vocabulary applied (from tasks.md "design wins" and the reducer source): `powerMenu` to `power`; `unread` to `blinkDot`; `criticalIndicator` to `showCriticalIndicator`; `holding` to `hold != null`; `toastPaused` to `toastHovered`; `hoverEnter`/`hoverLeave` to `Hover{on}`; `toastArrived`/`toastTimeout`/`toastDismissed` to `ToastShown`/`ToastTimeout`/`ToastDismissed`; `launcherOpen` to `LauncherToggle`; `polkitRequest`/`polkitCancelled` to `PolkitRequest`/`PolkitCancel`; `lockChanged` to `Locked{on}`; `screenRemoved` to `ScreensChanged`; `keyboardOwner` to `keyboard.owner`; mode derived by `viewFor`.

## Mechanical readbacks

- Spec copy (5 files): `diff -r` of each delta spec against its copy returned empty output (byte-identical).
- Archive move: `diff -r` of the pre-move snapshot against `openspec/changes/archive/2026-10-21-notch-foundation/` returned empty output. The source directory no longer exists under `openspec/changes/`.
- After readback, `state.yaml` in the archive was updated to the closed state (`archive: done`, `next: [none]`, paths and `archive_report` pointers). This is the only intentional post-readback edit to the archived folder and is recorded here.

## Traceability

- Delta specs in this folder (`specs/`) remain the pre-reconciliation copies that were moved.
- Main specs in `openspec/specs/` are the reconciled source of truth.

## Risks and follow-ups

- Manual checks listed under verify-report W3 remain pending (see above).
- Suggestions S1 and S2 are open for a later test-hardening change.
- The `Queue order (+1)` and "toast stays queued" scenarios must be implemented and un-deferred in `notch-notifications`.
- No commit was made. The archive move was staged with `git mv`, so the rename is in the index but not committed.

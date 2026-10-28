# Archive report: notch-workspaces-osd

**Date**: 2026-10-27
**Project**: quickshell-notch (engram project "quickshell notch")
**Artifact store**: openspec (engram archive report saved as `sdd/notch-workspaces-osd/archive-report`)
**Verdict at verify**: PASS WITH WARNINGS (0 CRITICAL, 4 WARNING, 2 SUGGESTION), per `verify-report.md`
**Outcome**: Archived and closed. Four new main specs created and two existing main specs updated under `openspec/specs/`. Deviations approved during apply and verify are folded into the main specs. Follow-ups are listed below and owned by no change yet.

## Observation IDs read (engram traceability)

| Artifact | Engram topic key | Observation ID | Notes |
|---|---|---|---|
| proposal | `sdd/notch-workspaces-osd/proposal` | #635 | Read in full. Consistent with the file. |
| spec | `sdd/notch-workspaces-osd/spec` | #636 | Read in full. Consistent with the delta files. |
| design | `sdd/notch-workspaces-osd/design` | #637 | Read in full. Design names `pageStart` and `slotCount`, replaced at apply (see Design deviations). |
| tasks | `sdd/notch-workspaces-osd/tasks` | #639 | Read in full. Says "~29 tasks"; `tasks.md` has 27. The file governs. |
| apply-progress | `sdd/notch-workspaces-osd/apply-progress` | #641 | Listed by search only, not read in full. The file `apply-progress.md` is authoritative. |
| verify-report | `sdd/notch-workspaces-osd/verify-report` | none | No Engram observation exists (search returned nothing). The file `verify-report.md` is authoritative. |

Other related observations, superseded by later evidence: #638 (design decisions), #724 ("PR 4 merged, PR 5 open (#23)", stale: PR 5 has since merged as de93aa5).

The openspec files in this folder are the authoritative copies, read in full. The observations are the Engram mirror.

## Final state at close

Final-state facts are ranked per the sdd-archive Final-State Authority section: repository evidence first, then the tasks artifact, then the launch-prompt facts, then the verify-report snapshot.

- **Code on main**: PRs #17 to #23 merged (stacked-to-main). Last feature merge is `de93aa5` (`feat(osd): live volume and brightness OSDs (notch-workspaces-osd 5/5) (#23)`). Verify-time commit was `15930b4`.
- **Tasks**: `tasks.md` has 27 checkboxes, all `[x]`. No `- [ ]` remains, so no stale-checkbox reconciliation was needed.
- **Tests and gate**: `make check` at archive time exits 0. `node --test tests/` reports 371 pass, 0 fail, 0 skipped. The smoke run prints `smoke: config loaded`. The verify-time count was also 371.
- **Manual checks**: per `verify-report.md`, the live checks (click to focus, external wpctl and brightnessctl changes, OSD presentation, mute toggle) were reported fine by the user in the live session. They are recorded as MANUAL-VERIFIED, not automated.

## Verify-report warnings at close (snapshot, rank 4)

Per `verify-report.md` at verification time (2026-10-27):

- **W1 (folded)**: the spec said "dimmed track". The implementation dims only the fill (`shell/components/Slider.qml`, fill opacity `Colours.mutedAlpha`), and the thumb stays opaque. Folded into the `osd-notch` Mute display requirement.
- **W2 (folded)**: the spec said the strip shows a fixed `slotCount`. The implementation shows `1..max(minSlots, active, highest occupied)`, with `Limits.workspaceSlots` as the minimum. Folded into `workspaces-notch` Strip model (plus a new Growth scenario) and `visual-tokens`.
- **W3 (open, follow-up)**: `Audio.setVolume` clamp glue, `Audio.toggleMute` and the workspace debounce timer have no direct unit test. The clamp maths is covered through `Slider.clamp`.
- **W4 (open, follow-up)**: workspace slots beyond about 6 overflow the 200 px TL slot and are clipped. Not covered by a test or a token fix.
- **S1 (not changed)**: `apply-progress.md` PR headings carry inconsistent totals ("of 5", "of 6", "of 7"). The archived `apply-progress.md` is kept verbatim as the audit trail.
- **S2 (open, follow-up)**: `Strings.brightness` and `Strings.volume` are unused. Kept deliberately for now.

## Design deviations folded into the main specs

| Design or delta wording | Final implementation | Where folded |
|---|---|---|
| `pageStart` (design) and `slotCount` (delta) | `slotRange`: `1..max(minSlots, activeId, highest occupied id on the monitor)`, with `Limits.workspaceSlots` = 5 as the minimum | `workspaces-notch` Strip model and Growth scenario; `visual-tokens` Workspaces and OSD tokens |
| "dimmed track" on mute | Only the fill dims, to `Colours.mutedAlpha` 0.8; the thumb stays opaque | `osd-notch` Mute display (requirement text and table) |
| `osdValueWidth` token (design) | Removed. The number is sized to its text and the bar takes the rest | `osd-notch` Presentation (manual) |
| (not in delta) | New `Colours.fillMix` 0.55: the slider fill is primary mixed into the black notch so the full-primary thumb stands out | `osd-notch` Presentation (manual); `visual-tokens` |
| (not in delta) | Track and fill are as tall as the thumb (`Layout.sliderHeight`); the fill ends at the thumb's outer edge; the slider is vertically centred in the notch body | `osd-notch` Presentation (manual) |

## Spec sync

### Mechanical copy (new capabilities)

Four new capabilities were copied with `cp -R` from the archived `specs/` folder into `openspec/specs/{domain}/`. The readback was run before the deviation folds, and was empty for every domain. Two of them (`audio-service`, `brightness-service`) needed no folds, so their readback is empty after the folds too.

| Domain | Action | Requirements |
|---|---|---|
| `workspaces-notch` | Created (folded: Strip model, Growth scenario) | 5 |
| `audio-service` | Created | 3 |
| `brightness-service` | Created | 3 |
| `osd-notch` | Created (folded: Mute display, Presentation) | 5 |

### Merge (existing capabilities)

Merged mechanically with an awk splice (MODIFIED blocks replaced by name, ADDED blocks appended, `(Previously: ...)` annotations dropped). The fold wording was then applied with exact edits.

| Domain | Action | Details |
|---|---|---|
| `shell-surfaces` | Updated | 2 MODIFIED: Placeholder visibility (TR only; TL, BL, VR live), Smoke mode (no processes or udev watchers) |
| `visual-tokens` | Updated | 1 ADDED: Workspaces and OSD tokens (folded: minimum slot count, fill mix, muted opacity) |

Requirement total in the change: 16 new + 2 modified + 1 added = 19, matching `verify-report.md`.

## Archive contents

- `proposal.md`, `design.md`, `tasks.md`, `apply-progress.md`, `verify-report.md`, `state.yaml`: moved, unchanged apart from `state.yaml` (archive done, artifact paths updated to this folder, `main_specs` and `archive_report` added, `next: [none]`).
- `specs/`: the six delta specs, moved unchanged. Their content is the pre-fold wording; the main specs carry the folded wording (see the table above).

## Follow-ups (not fixed here; for a future change)

1. Workspace slots beyond about 6 are clipped in the 200 px TL slot (verify W4). Either widen the slot area or add a token-driven overflow rule.
2. Add unit coverage for the QML glue that is not in `shell/logic`: `Audio.setVolume`/`toggleMute` and the workspace debounce timer (verify W3).
3. Decide whether `Strings.brightness` and `Strings.volume` stay (verify S2).

## Integrity

The `diff -r` readbacks for the move and the copies are recorded in the archive phase result, not in this report. This report was written after the move and is excluded from the source-versus-archive comparison (it did not exist in the snapshot).

# Archive report: notch-center

**Date**: 2026-10-21
**Project**: quickshell-notch (engram project "quickshell notch")
**Artifact store**: openspec (engram archive report saved as `sdd/notch-center/archive-report`)
**Verdict at verify**: PASS WITH WARNINGS (0 CRITICAL, 4 WARNING, 3 SUGGESTION)
**Outcome**: Archived and closed. Six new main specs created and two existing main specs updated under `openspec/specs/`. No follow-up change is required by this archive; deferred items are listed below and owned by later changes.

## Observation IDs read (engram traceability)

| Artifact | Engram topic key | Observation ID |
|---|---|---|
| proposal | `sdd/notch-center/proposal` | #621 |
| spec | `sdd/notch-center/spec` | #622 |
| design | `sdd/notch-center/design` | #630 |
| tasks | `sdd/notch-center/tasks` | #625 |
| verify-report | `sdd/notch-center/verify-report` | #632 |

The IDs were resolved through `mem_search` at archive time. Only the 300-character previews were read for them. The openspec files in this folder are the authoritative copies and were read in full; the observations are the engram mirror.

## Final state at close

Final-state facts are ranked per the sdd-archive Final-State Authority section: repository evidence first, then the tasks artifact, then the launch-prompt facts, then the verify-report snapshot.

- **Code on main**: HEAD is `b8e3f2a` (`docs(sdd): verify notch-center`), verified with `git log`. The implementation landed in PRs #10 to #16 (stacked-to-main), with the feature commits up to `0f3e19b` (`feat(center): cava visualizer and content-sized idle notch (notch-center 7/7)`).
- **Tests**: `node --test tests/` at archive time, repository evidence: 215 pass, 0 fail, 0 skipped, exit 0. This matches the launch-prompt fact and supersedes nothing; the verify-time count was also 215.
- **Tasks**: `tasks.md` contains 43 checkboxes, all checked (`[x]`). `rg` for unchecked items (`- [ ]`) returned no matches, so no stale-checkbox reconciliation was needed.
- **Manual confirmation**: task 7.8 (real player run) was confirmed by the user, per `state.yaml` at apply close.

## Verify-report items at close (snapshot, rank 4)

Per `verify-report` #632 at verification time:

- **W1 (reconciled)**: the spec scenario "Midnight" (`msUntilMidnight` = 30000) had no matching function. Reconciled at archive: the main spec now describes the implemented `dayKey`-driven rollover (`Time.dayKey`, `dayChanged`). See the reconciliation table.
- **W2 (reconciled)**: stale names and wording (`idleLayout`, `selectIdleLayer`, `parseCavaFrame`, `barGeometry` shape, "line-power device", `classify` layer list without `plugged`, `Layout.batterySide`, symmetric `base + 2*extra` width). Reconciled at archive to the implemented names and shapes. Design and implementation win, per the verify Resolutions (2026-10-21).
- **W3 (deferred)**: a critical event is lost when the shell starts at or below 10%, because the store attaches its listener after the first refresh. Kept explicitly marked as DEFERRED to `notch-notifications` in `battery-service`.
- **W4 (accepted)**: manual-only evidence for QML scenarios, per ADR 0003 (verify Resolutions).
- **Suggestions, open**: unread-dot source not wired (DEFERRED to `notch-notifications`); Recorder is minimal, full port DEFERRED to `notch-control-center`; QML-level test harness is a possible later improvement.

## Remaining manual checks (opportunistic, not blocking archive)

Per the verify-report Resolutions, these stay manual and are not verified by this archive:

- Bar colour fallback to matugen `primary` for a track without art, and https art fallback.
- Media layer glyph with no art (idle) and expanded no-art glyph on real hardware.
- `pkill cava` restart then give-up after 3 (stub-covered by the agent only); cava missing from PATH.
- Cava CPU below about 2% of a core.
- Recording dot with a real recorder (only forced via `setRecording`); width unchanged.
- Midnight rollover live; narrow-monitor clamp live.
- Plug-in/unplug edge on the real charger and the `plugged` (80% limit) layer visually.

## Spec sync

Two kinds of change were applied: new capabilities were created from the delta files, and deltas were merged into existing main specs.

### Mechanical copy step (new capabilities)

Each new capability was copied with `cp` from the change folder into `openspec/specs/{domain}/spec.md`, then `diff -r` was run against the source. The verbatim output of every readback was empty.

```
== battery-service        diff-exit=0 (no output)
== media-service          diff-exit=0 (no output)
== system-status-services diff-exit=0 (no output)
== center-idle-view       diff-exit=0 (no output)
== center-expanded-view   diff-exit=0 (no output)
== audio-visualizer       diff-exit=0 (no output)
```

The reconciliation below was applied after that readback, as explicit model edits to the copied specs. Those edits are intentional and are listed in the table. The copies are therefore no longer byte-identical to the change folder; the pre-reconciliation bytes are the change folder copies, which were archived by move.

### Reconciliation table

| Capability | Action | Reconciliation applied |
|---|---|---|
| battery-service | Created | `plugged` derived from `UPower.onBattery` plus state (charging, full, pending-charge). `classify(input, {low})` returns `plugged` as a layer, with a new table row. `criticalStep(state, input, {critical})` uses `Limits.batteryCritical`. Override described via `applyOverride` and `Flags.batteryOverride`. Critical event at shell start at or below the limit marked DEFERRED to `notch-notifications`. |
| media-service | Created | Playback state named `playing`. Art accent points to `audio-visualizer`. |
| system-status-services | Created | Midnight scenario replaced: `msUntilMidnight` removed, rollover driven by `Time.dayKey` change and `dayChanged`. Time formatters named `shortDate(month, day, months)` and `clock(hours, minutes)` (24-hour). Recorder marked minimal; full port DEFERRED to `notch-control-center`. |
| center-idle-view | Created | `selectIdleLayer` renamed to `sideLayer(batteryLayer, playing)`. `idleLayout` replaced by `idleBase`, `sideExtent`, `sideWidth`, `idleWidth({base, side, layer, max})`; width is content-driven, with no numeric visual values in the spec. Previously-annotations removed. Unread-dot source marked DEFERRED to `notch-notifications`. Visualizer hidden while cava is unavailable. |
| center-expanded-view | Created | Week strip rows carry `weekday`; radius from `Limits.weekRadius`. Midnight scenario keyed to `dayKey`. Expanded width table expressed through `Layout.expandedWidth`, `Layout.expandedClockWidth` and the per-monitor max; numeric examples removed. |
| audio-visualizer | Created | `parseCavaFrame` renamed to `parseFrame(line, bars, maxRange)` with the token-count rule. `cavaConfig` clamping documented. `barGeometry(levels, {height, barWidth, gap, minHeight})` returns `{x, y, height}`, replacing `{top, bottom}` extents. Lifecycle tied to `Cava.wanted` (`sideLayer === "media"`), restart policy (`Timings.cavaRestart`, `Limits.cavaRetries`) and smoke gate. `pickAccent` and `Limits.accentMinLuma` documented; https art fallback accepted. Runtime dependency documented as optional. |
| shell-surfaces | Modified (delta MODIFIED applied) | Requirement "Idle centre content" replaced with the live-content version (date, time, rings, overlays, battery layers; tokens only). Scenario "Smoke (manual)" added. |
| visual-tokens | Modified (delta ADDED applied) | Requirement "Centre content tokens" appended. "Timings and layout": `Layout.idleWidth` (260) reference removed; there is no `Layout.idleWidth` or `Layout.batterySide` token, and the idle width is content-driven. |

Vocabulary applied (design and implementation win, per tasks.md "Naming" note and the verify Resolutions): `idleLayout` to `idleWidth`/`idleBase`/`sideExtent`; `selectIdleLayer` to `sideLayer`; `parseCavaFrame` to `parseFrame`; `barGeometry` `{values, height, minBar}` to `barGeometry(levels, {height, barWidth, gap, minHeight})`; `formatDate`/`formatTime` to `shortDate`/`clock`; `msUntilMidnight` to `dayKey`-driven `dayChanged`; "line-power device" to `UPower.onBattery`.

Numeric values were kept only where the spec already stated them as behaviour (battery thresholds 20 and 10, week-strip radius 3, token names). Visual tuning values (idle, expanded and side-layer widths) were removed from the spec text and now live in the tokens.

### Delta merge into existing main specs

Deltas were applied to `openspec/specs/shell-surfaces/spec.md` and `openspec/specs/visual-tokens/spec.md`. Those delta files are not full specs, so no byte copy applies; the merge was done by exact-match edits. The readback is the `diff -rq` of the `openspec/specs/` tree against a pre-merge snapshot taken before any edit:

```
Only in openspec/specs: audio-visualizer
Only in openspec/specs: battery-service
Only in openspec/specs: center-expanded-view
Only in openspec/specs: center-idle-view
Only in openspec/specs: media-service
Files .../pre-merge/specs/shell-surfaces/spec.md and openspec/specs/shell-surfaces/spec.md differ
Only in openspec/specs: system-status-services
Files .../pre-merge/specs/visual-tokens/spec.md and openspec/specs/visual-tokens/spec.md differ
```

No requirement of `center-notch-state`, `hypr-dispatch` or `session-service` was touched. No destructive removal of a requirement occurred; the only removals were the stale scenario text and names listed above, each replaced by the implemented equivalent.

## Mechanical readbacks

- Change folder move: a recursive snapshot was taken with `cp -R` before the move, then `git mv openspec/changes/notch-center openspec/changes/archive/2026-10-21-notch-center` was run. The source directory was confirmed absent. The verbatim readback `diff -r "<snapshot>" openspec/changes/archive/2026-10-21-notch-center` produced no output and exit status 0.
- Spec copy readbacks: see the "Mechanical copy step" block above (all empty, exit 0).
- Post-readback edits in the archived folder: `state.yaml` was updated to the closed state (`archive: done`, `next: [none]`, archive and verify pointers, `main_specs` list). `archive-report.md` was added. These two edits are the only changes made to the archived folder after the readback, and are recorded here as intentional.

## Traceability

- Delta specs in `specs/` of this folder remain the pre-reconciliation copies that were moved; they are the audit record of what the change proposed.
- Main specs in `openspec/specs/` are the reconciled source of truth for the implemented behaviour.

## Git state

- The archive move is staged with `git mv` (rename in the index). New main spec folders under `openspec/specs/` and edits to `shell-surfaces` and `visual-tokens` are unstaged working-tree changes.
- No commit was made in this phase.

## Risks and follow-ups

- Manual checks listed above remain pending and are opportunistic.
- DEFERRED to `notch-notifications`: critical battery event when the shell starts at or below the critical limit; unread-dot source (blinkDot slot exists, source not wired).
- DEFERRED to `notch-control-center`: full Recorder port (the Recorder is minimal in this change).
- Spec wording for the Recorder toggle "false after true" is covered only by manual evidence (verify matrix: M-agent, partial).
- No QML test harness exists; QML behaviour remains manual-only by project convention (ADR 0003).

# Verification Report: notch-workspaces-osd

Mode: Strict TDD (openspec). Date: 2026-10-27. Verdict: PASS WITH WARNINGS.

Envelope: 0 CRITICAL, 4 WARNING, 2 SUGGESTION. Specs: 6 capabilities, 19 requirements, 33 scenarios (12 are manual-only).

## Completeness

| Metric | Value |
|---|---|
| Tasks total | 27 (1.1-5.3) |
| Tasks complete | 27 |
| Tasks incomplete | 0 |
| PRs merged to main | #17-#21, #22, #23 (HEAD de93aa5) |

## Build and tests

| Command | Exit | Result |
|---|---|---|
| `make check` (fmt-check, lint, test, smoke) | 0 | 371 tests, 371 pass, 0 fail, 0 skipped; `smoke: config loaded` |

Coverage tool: none configured; coverage analysis skipped (not a failure). Type checker: none (QML lint is part of `make check`, green).

## TDD compliance

| Check | Result | Details |
|---|---|---|
| TDD evidence reported | OK | Tables per PR in apply-progress.md |
| Test files exist (RED) | OK | workspaceStrip, reveal, slider, osd, cornerLayout, surfaceLayout, brightness tests all present |
| GREEN confirmed | OK | All pass in the full run |
| Triangulation | OK | Tables with multiple rows per behaviour |
| Safety net | OK | Whole-suite runs before and after reported |
| QML-only tasks (3.1-3.4, 4.3-4.5, 5.1-5.3) | N/A, justified | No pure logic; gate is `make check` plus runtime runs; manual-by-user per openspec/config.yaml |

Assertion quality: no tautologies, ghost loops or type-only assertions found in the new test files (spot-checked slider, brightness, workspaceStrip); table-driven tests assert exact values. Layer: all unit (node --test).

## Spec compliance matrix

| Capability / requirement | Evidence | Status |
|---|---|---|
| workspaces-notch: Strip model (symbol table, isolation) | workspaceStrip.test.mjs (stripFor, slotRange) passes | COMPLIANT |
| workspaces-notch: Window filtering | isNormalWindow table, passes | COMPLIANT |
| workspaces-notch: Reveal triggers and debounce | diffSnapshots + refreshesSnapshot tests pass; `wsDebounce` 150 token; debounce timer itself in QML, runtime-checked in PR 3 | COMPLIANT (timer manual) |
| workspaces-notch: Special pin / unpin | stripFor special + reveal Pin/Unpin rows pass | COMPLIANT |
| workspaces-notch: Click to focus (manual) | Reported fine by the user in live session | MANUAL-VERIFIED |
| audio-service: Reactive sink, no sink | Runtime probe in PR 4 (volume, muted read); external `wpctl` change tracking: user live session | MANUAL-VERIFIED |
| audio-service: Clamp table | `Slider.clamp` table tested in slider.test.mjs; `setVolume` calls it (Audio.qml:29) | COMPLIANT (indirect) |
| audio-service: Toggle, smoke safety | QML glue (Audio.qml:32-33), smoke gate present, `make smoke` green | COMPLIANT (smoke); toggle MANUAL-VERIFIED |
| brightness-service: Set table, Parse table | brightness.test.mjs (setArgs -5/42.6/130, percentOf 96/255=38) passes | COMPLIANT |
| brightness-service: Reactive updates, smoke | Probe matched brightnessctl; smoke gates at Brightness.qml:25,45,102; external udev change MANUAL-VERIFIED by user | COMPLIANT / MANUAL |
| osd-notch: Slider maths (value/position/wheel/tap-drag) | slider.test.mjs passes | COMPLIANT |
| osd-notch: Reveal state machine | reveal.test.mjs 12-row table passes | COMPLIANT |
| osd-notch: Startup gate | reveal Ready-gate rows and osd.test.mjs shouldReveal pass | COMPLIANT |
| osd-notch: Mute display, unavailable | osd.test.mjs (unavailable, mute) + levelGlyph tests pass; visuals MANUAL-VERIFIED | COMPLIANT |
| osd-notch: Presentation (manual) | User reviewed live; look iterated | MANUAL-VERIFIED |
| shell-surfaces: Placeholder visibility, smoke mode | Only TR keeps `showPlaceholders`; `make smoke` green with no processes | COMPLIANT |
| visual-tokens: tokens resolve, literal scan | Tokens in Limits/Timings/Strings/Layout/Colours; literal scan of workspaces/osd/Slider QML returned no hits | COMPLIANT |

## Design coherence

| Decision | Followed | Note |
|---|---|---|
| Pure logic in shell/logic, QML as glue | Yes | |
| `slotRange` replaces design `pageStart` | Deviation, documented | Noted for archive |
| `osdValueWidth` token | Removed, documented | Number sized to its text; bar shortens a few px at 100 |
| New tokens `fillMix`, `mutedAlpha`, `windowFrom`/`parseActiveSpecial`/`refreshesSnapshot`, `displayPercent`, `accumulateWheel`, `rawVolume` | Additions, documented | |
| Only the fill dims when muted | Deviation from "dimmed track" wording | Matches intent; user approved |

## Issues

CRITICAL: none.

WARNING:
1. `osd-notch` Mute table and spec text say "dimmed track"; implementation dims only the fill (shell/components/Slider.qml:76-77). User-approved; update spec wording at archive.
2. `visual-tokens` spec lists slot count as a token ("default = old maxVisible"); implementation exposes a minimum slot count that grows with active/occupied ids (spec "Strip model" says `slotCount` slots). Documented deviation (`slotRange`); sync specs at archive.
3. `Audio.setVolume` clamp and `toggleMute` (shell/services/Audio.qml:26-35) and the workspace debounce timer have no direct unit test (QML glue). Clamp maths is covered via `Slider.clamp`; runtime/user checks cover the rest.
4. Slots beyond about 6 overflow the 200 px TL slot and are clipped (apply-progress PR 3); not covered by a test or token fix.

SUGGESTION:
1. apply-progress.md PR headings carry inconsistent totals ("of 5", "of 6", "of 7"); tidy at archive.
2. `Strings.brightness`/`volume` are unused; remove or keep deliberately.

## Verdict

PASS WITH WARNINGS. No CRITICAL issues; ready for sdd-archive. At archive, fold the documented deviations (items 1, 2, `pageStart`, `osdValueWidth`) into the main specs.

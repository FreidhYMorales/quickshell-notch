# Proposal: Notch foundation (shell skeleton + centre state machine)

Plan row: `docs/plans/notch/plan.md` "Implementation phases" #1 `notch-foundation` (6.25 dev-days).

## Intent

Every later phase needs per-monitor surfaces, tokens, safe smoke runs and a tested centre-notch reducer. Building them first avoids the old attempt's failures (click-swallowing strip, stacked exclusive zones, scattered literals). Success: `qs -c notch` shows an idle black notch with ears on every monitor, and the old bar stays the daily shell.

## Scope

### In Scope
- Per-monitor `Variants -> Scope -> PanelWindow`: invisible spacer (sole exclusive zone, `reserveSpace` toggle); empty TL/BL/C/VR/TR surfaces with input masks and `ExclusionMode.Ignore`
- Concave ears: reuse `EarCurve.js`/`NotchEarShape`; generalise `CornerEarShape` to any corner
- Tokens in `shell/config/`: Fonts (IosevkaTerm Nerd Font once), Timings, Layout (max centre width per monitor), Colours (`paletteFor(screen)`, matugen dark scheme), Strings
- `NOTCH_SMOKE` mode skipping spacer zone, NotificationServer, PolkitAgent, IdleMonitors, IpcHandlers, BG, state writes
- `Session` singleton (`lockRequested`, `locked`); `Hypr` service with one dispatch wrapper over `hl.dsp.*`
- Pure reducer in `shell/logic/*.mjs` (strict TDD): priorities, per-monitor instances, global inputs, all mid-flow rules
- Idle centre notch with placeholder content

### Out of Scope
- Real services (Battery, Mpris, Audio, Notifs), real notch content
- BG/wallpaper surface, lock, state import, cutover (phase 7)

## Capabilities

### New Capabilities
- `shell-surfaces`: per-monitor surfaces, spacer zone, masks, ears, smoke mode
- `visual-tokens`: config token singletons, per-monitor palette
- `center-notch-state`: reducer, priorities, global/per-monitor inputs, mid-flow rules
- `session-service`: lock request/flag contract
- `hypr-dispatch`: single dispatch wrapper

### Modified Capabilities
None (no specs exist yet).

## Approach

Logic first: reducer as pure `(state, event) -> state` with `node --test`, no Qt imports. QML only paints reducer output. Surfaces are fixed-size; shapes animate inside. Smoke gating reads `NOTCH_SMOKE` once in a config token.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `shell/shell.qml` | Modified | Mount per-monitor surfaces |
| `shell/config/` | New | Token singletons + qmldir |
| `shell/components/` | New | Ear shapes, NotchZone |
| `shell/notches/center/` | New | Idle placeholder |
| `shell/services/` | New | `Session`, `Hypr` |
| `shell/logic/`, `tests/` | New | Reducer + tests |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Exceeds 400-line budget | High | Chained PRs: reducer, tokens/services, surfaces/ears |
| Mask gaps swallow clicks | Med | Manual click-through check per surface |
| Reducer rules ambiguous | Med | Question round below; spec scenarios per rule |
| `hl.dsp.*` bridge drift | Low | Single wrapper |

## Rollback Plan

Additive; old bar untouched. Revert the change's commits or stop `qs -c notch`.

## Dependencies

- Quickshell 0.3.2, Hyprland with `hl.dsp.*`, matugen output, IosevkaTerm Nerd Font

## Success Criteria

- [ ] Idle notch with ears on every monitor via `qs -c notch`
- [ ] Clicks pass through outside masks; only spacer reserves space
- [ ] `make check` green; smoke run leaves the session untouched
- [ ] Reducer tests cover every priority and mid-flow rule

## Proposal question round

Assumptions needing user review:
1. Idle placeholder = static text, no data.
2. Without a toast source, the reducer still models Toast/critical `!` (driven by tests only).
3. `Session.locked` is set only by tests/IPC-less stubs until phase 7.
4. Hot-plug: surfaces appear/disappear with monitors now; the reducer handles screen removal.

Questions (resolved 2026-10-21; assumptions 1-4 accepted):
- TL/BL/VR/TR placeholders: invisible by default; a debug token `showPlaceholders` makes them visible for manual mask/ear checks.
- Reserved strip: one idle-height token in logical units, identical on every monitor (Hyprland applies each monitor's scale).
- Cross-monitor effects (already settled in plan-review-2 R2-3): toast queue, suppression, dismiss/seen and lock are global; hover, Expanded and keyboard states are per monitor (keyboard states stay on the monitor where they opened).

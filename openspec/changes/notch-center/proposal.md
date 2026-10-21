# Proposal: Centre notch content (idle, battery layers, expanded hover)

Plan row: `docs/plans/notch/plan.md` "Implementation phases" #2 `notch-center` (4.25 dev-days).

## Intent

The centre notch shows a placeholder. To replace the old bar's clock, system meters, battery and media widgets, it needs real data and the idle + expanded views. Success: `qs -p shell/shell.qml` shows live idle content and a working hover view.

## Scope

### In Scope
- Services: `Battery` rewrite on `Quickshell.Services.UPower` (present/plugged/charging/full, `pluggedIn` edge, percentage); `Mpris` rewrite (reactive, prefers the playing player, `hasPlayer`); `SysInfo`, `Time` and `Recorder.recording` reused from the old config
- Idle: `(cpu ring) date · time (ram ring)` symmetric, `ArcMeter` reuse, unread-dot slot (`blinkDot`), red recording dot
- Static charging layer (icon left, % right) and red low-battery layer (< 20%, unplugged); symmetric growth, clock never moves
- 10% critical battery hook: one-shot effect only (toast UI arrives in `notch-notifications`)
- Expanded hover: media (art, title, album, artist, prev/play/next) + clock and week strip (today ±3); without a player only the narrower clock card; width ≤ `Layout.centerMaxWidth`
- Strict TDD `shell/logic/`: battery classification + thresholds + one-shot, week-strip math (midnight rollover, locale-independent), player selection, idle widths, formatting

### Out of Scope
- Charging animation/glow, low-battery breathing glow, month view/scroll/back-to-today, OLED pixel shift (SHOULD, `notch-polish-*`)
- Toast UI/queue, `Notifs` rewrite (unread source), richer recording UI

## Capabilities

### New Capabilities
- `battery-service`: UPower states, edge events, dev override
- `media-service`: reactive Mpris, player selection, controls
- `system-status-services`: SysInfo, Time, Recorder reuse contract
- `center-idle-view`: idle row, rings, overlays, battery layers, symmetric widths
- `center-expanded-view`: media column, clock + week card, no-player layout

### Modified Capabilities
- `shell-surfaces`: "Idle centre content" drops the static placeholder for live content
- `visual-tokens`: adds battery thresholds (20/10), critical red colour, week radius (3), expanded widths and new strings
- ~~`center-notch-state`~~: NOT modified (coordinator decision). The one-shot 10% tracking (fire once, re-arm on plug-in) is battery-domain logic and lives in the pure battery logic module / `battery-service`. In `notch-notifications` it requests a critical notification from `Notifs`; the reducer then sees an ordinary critical `ToastShown`, which it already handles.

## Approach

Services expose raw data; new `.mjs` modules decide states, widths and dates; QML paints. Reuse old `ArcMeter`, `CalendarCard`, `MediaSection` with tokens replacing literals. No polls beyond the reused `SysInfo` cadence; no V4-incompatible syntax.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `shell/services/` | New | Battery, Mpris, SysInfo, Time, Recorder |
| `shell/logic/`, `tests/` | New | Pure modules + tests |
| `shell/components/` | New | ArcMeter |
| `shell/notches/center/` | Modified | Idle, layers, Expanded, store wiring |
| `shell/config/` | Modified | Tokens, strings |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Exceeds 400-line budget | High | Slices: (1) logic + tests, (2) services + tokens, (3) idle + layers, (4) expanded |
| UPower lacks a distinct "plugged" state | Med | Derive from line-power device; test classification |
| Old components carry literals/V4 issues | Med | Tokenise on port; `v4Compat` test |
| Expanded overlaps OSDs on narrow monitors | Low | Clamp to `centerMaxWidth` |

## Rollback Plan

Additive except the centre notch; old bar untouched. Revert the slice commits or stop `qs -p`.

## Dependencies

- `notch-foundation` (archived); Quickshell UPower/Mpris modules; old config read-only

## Success Criteria

- [ ] Idle shows live date/time and CPU/RAM rings on every monitor
- [ ] Plug/unplug and battery override toggle the layers without moving the clock
- [ ] Hover shows media + week strip; no player shows the clock card only
- [ ] `make check` green; logic tests cover every listed rule

## Proposal question round

Skipped by orchestrator: decisions come from the approved plan and its review resolutions.

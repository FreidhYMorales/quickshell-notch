# Design: Centre notch content

## Technical Approach

ADR 0002: services normalise Quickshell data; pure `.mjs` modules decide layers, the critical one-shot, widths, the week strip, the player and formatting; QML paints `CenterStore.viewFor(screen)` plus service values. The centre surface stays fixed-size (ADR 0004); one shape item animates idle ↔ expanded and is the input mask.

## Architecture Decisions

| Decision | Choice | Rejected | Rationale |
|---|---|---|---|
| "Plugged" source | `plugged = !UPower.onBattery \|\| state ∈ {charging, full, pending-charge}` | A LinePower device lookup (`UPowerDevice` has no `online` property in the installed qmltypes) | `onBattery` is the daemon's line-power aggregate. `pending-charge` covers charge thresholds |
| Battery device | `UPower.displayDevice`, present = `ready && isLaptopBattery && isPresent` | Iterating `UPower.devices` | The composite device; desktops report no battery |
| Enum → logic | The service maps `UPowerDeviceState.*` to the strings `charging, discharging, full, empty, pending-charge, pending-discharge, unknown` | Numeric enums in `logic/` | Logic stays free of Qt and readable |
| One-shot 10% | `criticalStep` in `battery.mjs`; `Battery` holds `armed` | Reducer state (`center-notch-state` unchanged) | Battery-domain rule, per coordinator decision |
| Critical effect | `Battery.criticalReached()` signal. `CenterStore` logs it until `notch-notifications` | A toast now | Toast UI is out of scope |
| Mpris reactivity | A binding over `Mpris.players.values[i].playbackState` calls `selectPlayer` | 1 s poll (old) | Binding dependency tracking gives events with no poll. This build exposes `playbackState`/`isPlaying`, **not** `playbackStatus` (the AGENTS.md gotcha is stale) |
| Clock text | `format.mjs` with month and weekday names from `Strings` | `Qt.formatDate` | Locale-independent and testable |
| Time cadence | `SystemClock.Minutes` | Seconds | No seconds are shown, so it wakes up less |
| Surface size | Slot `c.height = tokens.expandedHeight ?? idleHeight`; the width stays `layoutFor().c.width` (≤ `centerMaxWidth`) | Resizing the window | ADR 0004: no flicker. The mask follows the shape |
| Recorder | A minimal singleton: `recording` + `setRecording()` (Session pattern); the process port moves to `notch-control-center` | Full port now | Its start/stop UI arrives with the Rec tile. It saves ~300 lines |
| Thresholds | New `config/Limits.qml`: `batteryLow 20`, `batteryCritical 10`, `weekRadius 3` | Using `Flags` or `Layout` | These are not flags and not geometry |

## Data Flow

    UPower ─► Battery ──fromUPower/classify/criticalStep──► layer, percentage, criticalReached ─► CenterStore (log)
    Mpris  ─► Mpris   ──selectPlayer──► player, hasPlayer
    /proc  ─► SysInfo ──sysStats──► cpu, ram          Time ─► now, dayKey
                     │
    CenterSurface: view = CenterStore.viewFor(name)
      shape {w,h} = centerLayout(mode, layer, hasPlayer, slot.width)  ── mask + NotchZone
        ├─ CenterIdle      (mode !== "expanded")
        └─ CenterExpanded  (mode === "expanded": CenterMedia + CenterClockCard)

## File Changes

| File | Action | Description |
|---|---|---|
| `shell/logic/{battery,sysStats,calendar,media,centerLayout,format}.mjs` | Create | Pure rules |
| `tests/<same>.test.mjs` | Create | One suite per module |
| `shell/logic/surfaceLayout.mjs` + test | Modify | Optional `expandedHeight` for `c` |
| `shell/services/{Battery,Mpris,SysInfo,Time,Recorder}.qml` + `qmldir` | Create | Data singletons |
| `shell/config/Limits.qml` + `qmldir` | Create | Thresholds and week radius |
| `shell/config/{Layout,Colours,Strings,Flags}.qml` | Modify | Widths and heights, `critical` red + `trackAlpha`, names/fallbacks/glyphs, `batteryOverride` (dev) |
| `shell/components/ArcMeter.qml` + `qmldir` | Create | Port: colours as properties, `Fonts.family`, `Anim` |
| `shell/components/NotchZone.qml` | Modify | `openDelay` (`Timings.hoverOpen`) separate from the close debounce |
| `shell/notches/center/{CenterExpanded,CenterMedia,CenterClockCard}.qml` + `qmldir` | Create | Expanded views |
| `shell/notches/center/{CenterSurface,CenterIdle,CenterStore}.qml` | Modify | Shape and mask, live idle row, critical hook |
| `AGENTS.md` | Modify | Mpris gotcha: `playbackState`/`isPlaying` |

## Interfaces / Contracts

```js
// battery.mjs
fromUPower({ present, onBattery, state, fraction })
  -> { present, plugged, charging, full, percentage }   // percentage = round(clamp(fraction)*100)
classify(input, limits) -> "none"|"charging"|"full"|"low"   // spec table
applyOverride(input, override) -> input        // Object.assign, no spread
criticalStep({ armed }, input, limits) -> { fire, armed }   // <= critical, re-arm on plugged
edges(prev, next) -> { pluggedIn, unplugged, fullReached }
// sysStats.mjs
parseCpu(text) -> {idle,total}|null; cpuPercent(prev,next); parseRam(text) -> percent|null
// calendar.mjs (y,m,d fields + Date.UTC math, DST/locale-free)
weekStrip({year,month,day}, radius) -> [{ year, month, day, weekday /*0=Mon*/, today }]
dayKey(date fields) -> "YYYY-MM-DD"
// media.mjs
selectPlayer([{ id, state }]) -> id | null   // first "playing", else first
trackText({title,album,artist}, fallbacks) -> {title,album,artist}
// centerLayout.mjs
idleWidth({ base, side, layer, max }) -> base + (layer !== "none" ? 2*side : 0), capped at max
expandedWidth({ hasPlayer, full, clockOnly, max }) -> min(hasPlayer ? full : clockOnly, max)
shapeFor(mode, widths, heights) -> { width, height }
// format.mjs
clock(h, min) -> "14:32"; shortDate(m, d, months) -> "Mar 20"
```

Service APIs: `Battery {present, plugged, charging, full, percentage, layer; signals pluggedIn, unplugged, fullReached, criticalReached}`; `Mpris {player, hasPlayer, title, album, artist, artUrl, playing, canPrev, canNext; togglePlay(), next(), previous()}`; `SysInfo {cpu, ram}` (FileView + `Timings.sysPoll` 2 s); `Time {now, dayKey; signal dayChanged}` (emitted when `dayKey` changes); `Recorder {recording}`.

Idle row: `[bat icon] (cpu) date · time (ram) [percent]` + `rec`/unread dots in the side padding. The battery slots have the fixed width `Layout.batterySide` on both sides, so the clock stays centred.

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Unit | All rules; midnight/month/year edges, full, no battery, override, re-arm, caps | Strict TDD, `node --test`, `v4Compat` |
| Smoke | Services load (UPower/Mpris absent → no errors) | `make smoke` |
| Manual | Plug/unplug, `batteryOverride`, hover, no player, masks | `qs -p shell/shell.qml` |

## Threat Matrix

N/A: no routing, shell, subprocess, VCS or executable-classification boundary (only `/proc` and DBus).

## Migration / Rollout

Five stacked PRs (logic needs two slices to fit 400 lines with tests):

1. `battery` + `sysStats` + tests (~320)
2. `calendar`, `media`, `centerLayout`, `format` + tests (~350)
3. Services, config tokens, `surfaceLayout` height, AGENTS.md (~330)
4. ArcMeter, idle row, battery layers, shape/mask, NotchZone delay, critical hook (~340)
5. Expanded views (~300)

## Open Questions

- [ ] Is `UPowerDevice.percentage` 0–1 on this build? The design assumes yes; check with one log line in slice 3.
- [ ] The spec says `plugged` comes "from the line-power device", but the design uses `UPower.onBattery` (the daemon's line-power aggregate), because `UPowerDevice` has no `online` property. Should the spec wording be updated?
- [ ] Is the Recorder deferral acceptable? The spec says "reused". Until then the red dot is only testable via `setRecording`.
- [ ] Do the SDD artifacts go in slice 1 (over budget) or in a pre-reviewed docs-only PR?

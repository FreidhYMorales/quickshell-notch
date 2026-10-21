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

## Scope addition: idle media layer + visualizer

Approved after PR 3. While a player is playing and the notch is idle, the side slots show a mini album art LEFT and a live, mirrored (Honor-style) visualizer RIGHT. It reuses the symmetric side-slot mechanism of the battery layers, so the clock never moves.

### Decisions

| Decision | Choice | Rejected | Rationale |
|---|---|---|---|
| Side-layer priority | Pure `sideLayer(batteryLayer, playing)`: `low` > `media` > `charging`/`plugged`/`full` > `none` | Adding `media` inside `battery.classify` | Battery logic stays battery-only; the merge is a centre-notch rule |
| Charging while playing | `media` wins; the plug-in glow is a later SHOULD hook on `Battery.pluggedIn` | Alternating layers | No flicker; glow is out of scope (`notch-polish-*`) |
| Width | `idleWidth` unchanged; the caller passes `side = sideWidth(layer, {battery, media})` | A new width function | PR 2 contract and tests stay valid |
| Spectrum source | `cava` raw ASCII output via `Process` + `SplitParser` | PipeWire/Qt multimedia in QML; fake animation | Real data, no C++ module, one small process |
| Who starts cava | `Cava.wanted` (plain property) driven by a `Binding` in `CenterStore` from `sideLayer === "media"` | `Cava` reading `Battery`/`Mpris` itself | `Cava` stays a generic spectrum service; policy stays in the store |
| Config delivery | `FileView.setText(cavaConfig(...))` to `Quickshell.cachePath("cava.conf")`, start on `saved` | `sh -c` heredoc or `-p /dev/stdin` | Fixed argv `["cava", "-p", path]`, no shell boundary |
| Bar rendering | `Repeater` of `Rectangle`s, no `Behavior` on height | `Canvas` repaint; animated heights | cava already smooths; at 30 fps animations would lag; few items |
| Colour | `ColorQuantizer { source: Mpris.artUrl; depth: 2; rescaleSize: 64 }`; pure `pickAccent` picks the most saturated colour above a luma floor; fallback matugen `primary` | Fixed `primary` only | Verified API in `quickshell-core.qmltypes`: `colors` (QColor list, read-only), `source`, `depth`, `rescaleSize`, `imageRect` |
| Art thumb | `ClippingRectangle` (`Quickshell.Widgets`) + `Image`, fallback glyph | Masking with `OpacityMask` | Built-in rounded clip, no Qt5Compat |

### Lifecycle and CPU

- `Cava.running = wanted && !Flags.smoke && available`. `Process.running` follows it: pause, stop, no player or a `low` battery set `wanted=false`, so cava is terminated and `levels` reset to zeros (flat line).
- Start: write the config, then `running=true` on `FileView.saved`. The config is rewritten only when its text changes.
- Crash: `onExited` while `wanted` restarts after `Timings.cavaRestart` (2000 ms), at most `Limits.cavaRetries` (3) per play session; then `available=false` + `console.warn`, and the visualizer hides while the art stays. A missing binary takes the same path.
- Budget: `Limits.cavaBars` 6, `Limits.cavaFps` 30, `Limits.cavaMaxRange` 100, `channels = mono`. Expected cost: cava below 2% of one core; 6 rectangle updates per frame. Nothing runs while paused.

Generated config (all values are integers from tokens):

    [general]  bars, framerate, autosens = 1
    [input]    (default autodetect: pipewire/pulse)
    [output]   method = raw, raw_target = /dev/stdout, data_format = ascii,
               ascii_max_range, bar_delimiter = 59, frame_delimiter = 10, channels = mono

### Data flow

    Battery.layer ─┐
    Mpris.playing ─┴► sideLayer() ─► CenterStore.sideLayer ─► Binding Cava.wanted
                                         │
    cava ─stdout─► SplitParser ─► parseFrame() ─► Cava.levels [0..1]
    CenterIdle: left = layer=="media" ? ArtThumb : battery icon
                right = layer=="media" ? Visualizer(levels, Mpris.artAccent) : percent
                width = idleWidth({ base, side: sideWidth(layer, sides), layer, max })

### File changes

| File | Action | Description |
|---|---|---|
| `shell/logic/sideLayer.mjs` + `tests/sideLayer.test.mjs` | Create | `sideLayer`, `sideWidth` |
| `shell/logic/visualizer.mjs` + `tests/visualizer.test.mjs` | Create | `cavaConfig`, `parseFrame`, `barGeometry`, `pickAccent` |
| `shell/services/Cava.qml` + `qmldir` | Create | Process, SplitParser, FileView config, restart policy |
| `shell/services/Mpris.qml` | Modify | `ColorQuantizer`, `artAccent`, `hasArtAccent` |
| `shell/components/{ArtThumb,Visualizer}.qml` + `qmldir` | Create | Rounded art with fallback; mirrored bars |
| `shell/notches/center/{CenterIdle,CenterStore}.qml` | Modify | Side-slot switch, `sideLayer`, `Binding` |
| `shell/config/{Layout,Limits,Timings}.qml` | Modify | `mediaSide`, `artSize`, `vizBarWidth`, `vizGap`, `vizMinHeight`, `vizHeight`; `cavaBars`, `cavaFps`, `cavaMaxRange`, `cavaRetries`, `accentMinLuma`; `cavaRestart` |
| `docs/development.md`, `AGENTS.md` | Modify | `cava` in the toolchain table and `pacman -S` line (optional at runtime); gotcha: visualizer never runs under `Flags.smoke` |

### Interfaces

```js
// sideLayer.mjs
sideLayer(batteryLayer, playing) -> "low"|"media"|"charging"|"plugged"|"full"|"none"
sideWidth(layer, { battery, media }) -> 0 | battery | media
// visualizer.mjs
cavaConfig({ bars, framerate, maxRange }) -> string   // ints clamped to [1, 64], [1, 60], [1, 1000]
parseFrame(line, bars, maxRange) -> number[] (0..1) | null   // "3;5;0;" ; wrong count/NaN -> null
barGeometry(levels, { height, barWidth, gap, minHeight })
  -> [{ x, y, height }]   // height = max(minHeight, level*height); y = (height - h)/2 (mirrored)
pickAccent([{ r, g, b }], { minLuma }) -> index | -1   // 0..1 channels, max saturation
```

`Cava {wanted, running, available, levels}`; `Mpris` adds `artAccent: color`, `hasArtAccent: bool`.

### Testing

Strict TDD for both modules: priority table (including charging + playing → `media`, low + playing → `low`), widths, config text and clamping, frame parsing (trailing delimiter, short/long frame, garbage, clamp above max), flat line at zero, mirror symmetry, accent pick (greys and darks rejected → -1). Smoke: `Cava` loads under `Flags.smoke` with no process. Manual: play/pause/quit, `pkill cava` (restart, then give up after 3), art with no colour, https art.

### Threat matrix

| Boundary | Applicability |
|---|---|
| Documentation-like paths, Git repository selection, commit state, push state, PR commands | N/A: no VCS/PR automation and no file classification |

Process boundary (not in the matrix, recorded as design requirements): fixed argv with no shell; the config contains only clamped integers (RED: `cavaConfig` with `"6\n[output]"`, NaN or negative values emits clamped integers only); stdout is untrusted (RED: `parseFrame` rejects malformed frames).

### Delivery

PR 4 (~340) has no room. Add two stacked PRs after PR 5:

6. `sideLayer` + `visualizer` logic and tests (~260)
7. `Cava`, `ArtThumb`, `Visualizer`, Mpris colour, `CenterIdle`/`CenterStore` integration, tokens, docs (~270)

Dependency: `cava` (extra repo). It is already present at `/usr/bin/cava` on the host, so no install is needed, but `docs/development.md` must list it. Without it, only the visualizer hides.

### Open questions (addition)

- [ ] Does `ColorQuantizer` load `https://` art (e.g. Spotify)? If not, colour falls back to `primary`. Caching remote art is out of scope.
- [ ] Should `ArtThumb` be created in PR 5 (shared with `CenterMedia`) to keep PR 7 smaller?
- [ ] Does the parallel spec update rename `idleWidth` to `idleLayout({base, extra, layer})`? This design keeps the merged `idleWidth`.

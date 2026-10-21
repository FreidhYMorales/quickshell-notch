# Design: Workspaces notch and volume/brightness OSDs

## Technical Approach

ADR 0002 split: `Workspaces`, `Audio` and `Brightness` normalise Hyprland, Pipewire and udev data into plain values. Pure modules decide the strip, triggers, reveal timing and slider maths. QML paints. Triggers do not come from raw events directly. Each relevant Hyprland event schedules one debounced snapshot, and `diffSnapshots` compares normal windows across snapshots. Dialogs and popups therefore never trigger, and moves know both source and destination (ready for the SHOULD fly animation). Surfaces stay fixed-size (ADR 0004); a shape slides inside them and a separate mask item follows the visible state.

## Architecture Decisions

| Decision | Choice | Rejected | Rationale |
|---|---|---|---|
| Trigger source | Raw events → `refreshToplevels()` + debounce (`Timings.wsDebounce`) → snapshot → `diffSnapshots` | Acting on `openwindow`/`movewindowv2` payloads | Payloads lack window type and the move source; one path handles debounce and filtering |
| Model access | Read `Hyprland.toplevels.values`/`monitors.values` imperatively in the debounce handler | Repeater probe (old widget) | The probe was needed for reactive `[i]` access; an event-driven snapshot needs none |
| Window data | `t.workspace`, `t.monitor` (reactive), `t.wayland?.parent` (transient-for) + `lastIpcObject` for `class`, `focusHistoryID`, `floating`, `mapped`, `hidden`, `size` | — | Verified in the qmltypes: no `focusHistoryID` property; `lastIpcObject` is filled by `refreshToplevels()`; `Toplevel.parent` exists |
| Normal window | `mapped && !hidden && class != "" && !hasParent`; a float counts only if its size is at least `Limits.floatMin{Width,Height}` | Ignoring every float | Spec filter table: dialogs (parent) and small floating popups out, floating apps in |
| Per-monitor slots | Page of `Limits.workspaceSlots` (5) ids containing that monitor's active id (`base = floor((active-1)/n)*n+1`). Occupancy, icons and triggers count only windows whose `monitor` is this one | Listing only existing workspaces | Matches the spec symbol table (1–5 when the active id is 2 or 4) and the isolation scenario; range-bound rules (1–5, 6–10) map to pages |
| Special | `activespecial` raw event → `specialByMonitor[mon]` | `HyprlandWorkspace.active` | AGENTS.md gotcha: never true for specials |
| App icon | `DesktopEntries.heuristicLookup(cls)?.icon` → `Quickshell.iconPath(icon, true)`; empty → `appInitial(cls)` | Old `list-apps.py` | Plan reuse map; verified in `quickshell-core.qmltypes` |
| Reveal state | A generic `reveal.mjs` reducer used by both notches (`pinned` included); one `Timer` per surface | Two copies; a global store | Same rules (gate, hover hold, drag hold, unpin restarts the timer); per monitor, no shared state |
| Flash on open | The `Trigger` event carries `flash {workspaceId, cls}`; cleared on hide | A separate timer | "A few seconds" equals the reveal window |
| Audio | `Pipewire.defaultAudioSink` + `PwObjectTracker`; `volume` stays 0..1 (spec); writes `audio.volume`/`audio.muted`; the shown number is `round(volume*100)` | `wpctl`/`pactl` processes | Reactive, no processes, safe under smoke |
| Value ranges | Slider is range-generic: volume `0..1` with `Limits.volumeStep 0.05`; brightness `0..100` with `Limits.brightnessStep 5`; results are rounded to 3 decimals | One percent scale | The spec fixes both ranges; rounding avoids `0.55000000001` |
| Brightness | `udevadm monitor --subsystem-match=backlight --udev` → `brightnessctl get`; `max` once; set coalesced (one in-flight process, latest pending value) | Polling | AGENTS.md: no forking polls |
| Startup gate | `Ready` reaches the reducer after `Timings.startupGate`; `shouldReveal` also needs `prev.available` and the same source, so the initial read never counts | Timer only | Late Pipewire binding and sink switches would flash |
| Animation | Shape `y` slides between `-height` and `0`; `maskBox.height = visible ? shape.height : 0` | Resizing `cornerPath` from 0 | Degenerate ear paths; ADR 0004 |
| Sizes | `surfaceLayout`: `tl.height = cornerHeight ?? idleHeight`, `bl/vr.height = osdHeight ?? idleHeight` | Fixed `idleHeight` | The corner body needs `idleHeight + earRadius`; the slider needs ≥ 36 px |

## Data Flow

    Hyprland rawEvent ─► Workspaces: refreshToplevels, debounce ─► snapshot
        snapshot ─► diffSnapshots(prev, next, mon) ─► triggered(mon, list)
        activespecial ─► specialByMonitor
    WorkspacesSurface(mon): strip = stripFor(...); reveal = stepReveal(Trigger|Hover|Timeout|Ready)
    Pipewire sink ─► Audio{available, sinkId, volume, muted} ┐
    udev ─► brightnessctl ─► Brightness{available, percent} ┴► OsdSurface(kind): shouldReveal ─► stepReveal
    Slider: valueAt / wheel ─► Audio.setVolume | Brightness.set; right-click ─► Audio.toggleMute

## File Changes

| File | Action | Description |
|---|---|---|
| `shell/logic/{workspaceStrip,reveal,slider,osd,brightness,cornerLayout}.mjs` | Create | Pure rules |
| `tests/<same>.test.mjs` | Create | One suite each |
| `shell/logic/surfaceLayout.mjs` + test | Modify | Optional `cornerHeight`, `osdHeight` |
| `shell/services/{Workspaces,Audio,Brightness}.qml` + `qmldir` | Create | Data singletons |
| `shell/components/Slider.qml` + `qmldir` | Create | Shared slider |
| `shell/notches/workspaces/WorkspaceSlot.qml` + `qmldir` | Create | Dot / icon / initial |
| `shell/notches/workspaces/WorkspacesSurface.qml` | Modify | Live strip, mask, click |
| `shell/notches/osd/OsdSurface.qml`, `shell/shell.qml` | Modify | `kind: "brightness"\|"volume"`, `mirrored` |
| `shell/config/{Layout,Timings,Limits,Strings}.qml` | Modify | Tokens below |
| `AGENTS.md`, `docs/development.md` | Modify | `lastIpcObject` gotcha; `brightnessctl`, `udevadm` |

Tokens: Layout `cornerHeight 44`, `osdHeight 36`, `wsSlot 22`, `wsSlotActive 28`, `wsIcon 16`, `wsPad 10`, `sliderHeight 24`, `osdPad 12`, `osdValueWidth 28`, `osdMinWidth 120`; Timings `wsDebounce 150`, `startupGate 1000` (`reveal` reused); Limits `workspaceSlots 5`, `volumeStep 0.05`, `brightnessStep 5`, `levelHigh 0.66`, `levelMid 0.33` (fractions of the range), `floatMinWidth 300`, `floatMinHeight 200`; Strings: Arch, `●`, `–`, `○`, special glyph map, volume/brightness level glyphs.

## Interfaces / Contracts

```js
// workspaceStrip.mjs   snapshot = { monitors: {[name]: {activeId}}, windows: [Win] }
// Win = { address, cls, workspaceId, monitor, focus, mapped, hidden, floating, hasParent, width, height }
isNormalWindow(win, { minFloatWidth, minFloatHeight }) -> bool
pageStart(activeId, slots) -> int
lastFocusedClass(windows, wsId) -> cls | null          // min focus, tie by address
stripFor({ activeId, windows, slots, special, flash })   // windows: normal, this monitor
  -> { pinned, special, items: [{ id, kind: "active"|"app"|"empty", cls }] }
diffSnapshots(prev, next, monitor, rules)
  -> [{ kind: "workspace"|"open"|"move", workspaceId, cls?, from? }]   // prev null -> []
specialName(wsName) -> string                           // "special:music" -> "music"
appInitial(cls, fallback) -> string                     // "org.gnome.Nautilus" -> "N"
// reveal.mjs
initialReveal() -> { ready, open, hover, hold, pinned, flash }
stepReveal(state, { type: "Ready"|"Trigger"|"Hover"|"Hold"|"Pin"|"Timeout", on?, flash? })
  -> { state, timer: "restart"|"stop"|"none" }   // Trigger before Ready: unchanged
isVisible(state) -> pinned || open
// slider.mjs   geo = { track, min, max }  (track = width - thumb)
clamp(v, min, max) -> number
valueAt(pos, geo) -> number;  positionOf(value, geo) -> px
notchesOf(angleDeltaY) -> int                           // ±1 per 120
wheel(value, notches, { step, min, max }) -> number
levelGlyph(fraction, muted, { high, mid }, glyphs) -> string
// osd.mjs      sample = { available, source, value, muted }
shouldReveal(prev, next) -> bool   // both available, same source, value or muted differs
// brightness.mjs
parseLevel(line) -> int | null; percentOf(current, max) -> int | null
setArgs(percent) -> ["brightnessctl", "set", "<0..100 int>%"] | null   // NaN -> null
// cornerLayout.mjs
cornerShape({ contentWidth, contentHeight, pad, ear, maxWidth, maxHeight }) -> { width, height }
```

Services: `Workspaces {snapshot, specialByMonitor; signal triggered(monitor, list)}`; `Audio {available, sinkId, volume (0..1), muted; setVolume(v), toggleMute()}` (`setVolume` clamps with `slider.clamp`; writes are no-ops under smoke); `Brightness {available, percent; set(pct)}` (no `Process` under `Flags.smoke`; missing binary or `max ≤ 0` → `available=false` + `console.warn`).

TL: content row `Arch + n slots` (height `idleHeight`) inside `CornerEarShape { anchor: "topLeft" }` sized by `cornerShape` (ears flare along the top and left edges). Click: `Hypr.dispatch("focus", [{workspace: id}])`; pinned special: `"workspace.toggle_special"`. OSD: `NotchEarShape` filling `slot.width × osdHeight`, hidden when `slot.width < Layout.osdMinWidth`; `mirrored` puts the value on the outer side. Every surface uses `WlrKeyboardFocus.None` (default `wantsKeyboard: false`).

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Unit | Filter, pages, strip kinds, flash, special pin, diffs (null prev, dialog open, move to special), reveal gate/hover/hold, slider clamps and wheel, glyph thresholds, `shouldReveal`, parse/argv | Strict TDD, `node --test`, `v4Compat` |
| Smoke | Services load; no `brightnessctl`/`udevadm` spawned | `make smoke` |
| Manual | Switch, open, move, special, click, keybinds, drag, scroll, mute, reload (no flash) | `qs -c notch` |

## Threat Matrix

| Boundary | Applicability |
|---|---|
| Documentation-like paths, Git repository selection, commit state, push state, PR commands | N/A: no VCS/PR automation or file classification |

Process boundary (design requirements): fixed argv, no shell; `setArgs` emits integers only (RED: `"50; rm"`, `NaN`, `-5`, `500` → clamped or `null`); stdout is untrusted (RED: `parseLevel` rejects garbage and negatives).

## Migration / Rollout

Additive, five stacked PRs to main, each ≤ 400 lines including tests and `tasks.md` progress:

1. `workspaceStrip` + tests (~340)
2. `reveal`, `slider`, `osd`, `cornerLayout`, `surfaceLayout` heights + tests (~350)
3. `Workspaces` service, tokens, `WorkspaceSlot`, `WorkspacesSurface`, AGENTS.md (~360)
4. `brightness.mjs` + tests, `Audio`, `Brightness`, development.md (~300)
5. `Slider`, `OsdSurface`, `shell.qml`, OSD tokens (~300)

This differs from the proposal order: shared reveal logic moves to slice 2 because the workspaces surface needs it.

## Open Questions

- [ ] Popups are detected with a size threshold (Hyprland has no window-type field). Is that heuristic acceptable?
- [ ] Should OSDs reveal on every monitor (plan) or only on the focused one (old behaviour)?
- [ ] Above 100% volume, `Audio.volume` reports 1 (spec clamp) while Pipewire may hold more. Should the real value be shown?
- [ ] Does hovering keep the workspace strip open? The spec states this only for OSDs; the design assumes yes, so slots can be clicked.
- [ ] A default-sink switch does not reveal the OSD. Is that acceptable?
- [ ] "Mirrored" puts the value on the outer side while the fill still grows left to right. Is that right?

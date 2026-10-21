# Design: Notch foundation

## Technical Approach

Logic first (ADR 0002): every decision is a pure `.mjs` function tested with `node --test`. QML singletons hold state and run effects, and per-monitor surfaces only paint `viewFor(state, monitor)`. The surfaces follow ADR 0004: fixed size, a mask on every surface, and the spacer is the only surface with an exclusive zone. The ear math from the old `EarCurve.js` moves into `logic/` so that it can be tested.

## Architecture Decisions

| Decision | Choice | Rejected | Rationale |
|---|---|---|---|
| Reducer topology | One root `reduce(state, event)` over `{global, monitors{}}`. Each monitor's slice is a "per-monitor instance" | N independent reducers synced by QML | Global rules (lock, toast suppression, screen removal) become a single atomic transition that tests can cover |
| Mode | Derived by priority in `viewFor`, not stored | A stored mode with a transition table | "Return to the previous state" (null polkit flow, toast ending while hovered) holds by construction |
| Side effects | `reduce` returns `{state, effects[]}`. `CenterStore` executes them | Calling services from the reducer | Keeps `logic/` pure, and tests can assert the effects |
| Keyboard states | One global `keyboard` slot with an `owner` monitor. Polkit is separate and preempts it | Per-monitor keyboard slots | Exclusive focus exists once, and states stay on the monitor that opened them. Opening power replaces the launcher |
| Ear shapes | `logic/earGeometry.mjs` builds SVG path strings. Shapes use `PathSvg` | Static `PathCubic`/`PathArc` slots (the old LIMITATION) | `CornerEarShape` gets any corner at runtime. The geometry is testable |
| Surface placement | `logic/surfaceLayout.mjs` computes x/width per slot from the screen width and tokens | Margins hand-tuned in QML | Proves the slots never overlap. Gives the max centre width per monitor |
| Smoke gating | `Flags.smoke = Quickshell.env("NOTCH_SMOKE") === "1"`, read once | Checking the environment in each file | A single source. Later phases wrap side-effectful items in `LazyLoader { active: !Flags.smoke }` |
| Dispatch | `Hypr.dispatch(name, args)` → `Quickshell.execDetached(["hyprctl","dispatch", expr])`, where `expr` comes from `logic/hyprDsp.mjs` | `Hyprland.dispatch` (does not work on this build); shell strings | Uses an argv list with no shell. Validates and escapes the Lua arguments in one place |

## Data Flow

    Quickshell.screens ─┐  Session.locked ─┐  (later: Notifs, Polkit)
                        ▼                  ▼
                 CenterStore.send(event) ── reduce() ──► effects ─► services
                        │ state
        Variants(screen) ─► CenterSurface: viewFor(state, screen.name) ─► paint
        NotchZone hover (debounced by Timings) ─► send(Hover)

## File Changes

| File | Action | Description |
|---|---|---|
| `shell/shell.qml` | Modify | `Variants` → `Scope` with Spacer, Workspaces (TL), Osd left (BL), Center, Osd right (VR), ControlCenter (TR) |
| `shell/config/{Fonts,Timings,Layout,Colours,Strings,Flags}.qml` + `qmldir` | Create | Singleton tokens. `Flags`: `reserveSpace`, `showPlaceholders`, `smoke`. `Colours.paletteFor(screen)` |
| `shell/services/{Session,Hypr}.qml` + `qmldir` | Create | Lock contract and the dispatch wrapper |
| `shell/components/{NotchSurface,SpacerSurface,NotchEarShape,CornerEarShape,NotchZone,Anim}.qml` + `qmldir` | Create | Base surface (mask, `ExclusionMode.Ignore`, focus), spacer, ears, hover hitbox, token-driven animation |
| `shell/notches/center/{CenterStore,CenterSurface,CenterIdle}.qml` + `qmldir` | Create | Store singleton, the surface, and the static placeholder |
| `shell/notches/{workspaces/WorkspacesSurface,osd/OsdSurface,controlcenter/ControlCenterSurface}.qml` + `qmldir` | Create | Empty placeholders (visible only with `showPlaceholders`) |
| `shell/logic/{centerState,centerView,earGeometry,surfaceLayout,palette,hyprDsp}.mjs` | Create | Pure logic |
| `tests/<same>.test.mjs` | Create | One suite per logic file |
| `shell/*/.gitkeep` | Delete | Replaced by real files |

## Interfaces / Contracts

```js
// centerState.mjs
initialState(monitorNames) -> State
reduce(state, event) -> { state, effects }
State = {
  global: { locked, dnd, blinkDot,
    toast:    { id, critical, phase: "shown" | "indicator" } | null,
    keyboard: { owner, kind: "launcher" | "power", sub, hold: { action } | null } | null,
    polkit:   { flowId, owner } | null },
  monitors: { [name]: { hovered, pinned, toastHovered } } }
Event.type: ScreensChanged{names} Hover{monitor,on} ToastHover{monitor,on}
  ExpandedToggle{monitor} LauncherToggle{monitor,sub} PowerOpen{monitor,action?}
  Close{monitor} HoldStart{action} HoldCancel HoldComplete
  ToastShown{id,critical} ToastTimeout{id} ToastDismissed{id}
  PolkitRequest{flowId,monitor} PolkitEnded{flowId} PolkitCancel
  Locked{on} Dnd{on}
Effect: {type:"polkit.cancel",flowId} | {type:"power.run",action}
// centerView.mjs: priority Polkit > Power > Launcher > Toast > Expanded > Idle
viewFor(state, monitor) -> { mode, sub, hold, toast, showCriticalIndicator, blinkDot,
                            keyboardFocus: "exclusive" | "none" }
// earGeometry.mjs
earCubic(...)  // ported unchanged
notchPath(w, h, er, cr) -> string
cornerPath(w, h, anchor, er, cr) -> string
// surfaceLayout.mjs
layoutFor(screenWidth, monitorName, tokens) -> { tl, bl, c, vr, tr: { x, width, height } }
// palette.mjs
parsePalette(jsonText) -> Palette | null      // fallback to the tokens on null
// hyprDsp.mjs
dspExpr(name, args) -> string | null          // null when the name or args are invalid
```

Mid-flow rules in `reduce`:
- `PolkitRequest` and `Locked{on}` clear `keyboard.hold`.
- `Locked{on}` also closes `keyboard`, clears hover and pinned, and emits `polkit.cancel`.
- `ScreensChanged` drops removed monitors. If a removed monitor owned `keyboard` or `polkit`, those close or cancel.
- When the toast is critical, `ToastTimeout` sets the phase to `indicator`. Otherwise it clears the toast.
- A toast is suppressed by DND (non-critical only) or while any keyboard state or polkit is open. Suppression sets `blinkDot`.

Surfaces:
- **Spacer**: anchored top, left and right, height `Layout.idleHeight`. Exclusive zone = idle height when `Flags.reserveSpace && !Flags.smoke`, otherwise `ExclusionMode.Ignore`. Mask is an empty `Region {}`.
- **Other surfaces**: `NotchSurface` with fixed width and height from `layoutFor`, anchored top + left with `margins.left = x`. Mask is `Region { item: maskItem }`, the shape's bounding item, so it is empty while a placeholder is hidden. Keyboard focus is `Exclusive` only when `view.keyboardFocus` asks for it.

Colours:
- `Colours.qml` watches matugen `colors.json` with a `FileView` and parses it with `parsePalette`.
- `paletteFor(screen)` returns `overrides[screen.name] ?? global`. The overrides map stays empty until phase 7.

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Unit | Reducer priorities, every mid-flow rule, the view selector, ear paths, layout without overlap, palette parsing, dispatch escaping | Strict TDD, `node --test tests/` |
| Smoke | The config loads with `NOTCH_SMOKE=1` and no zone is reserved | `make smoke` |
| Manual | Ears on every monitor, click-through outside the masks, hot-plug | `qs -c notch`, `showPlaceholders` |

## Threat Matrix

Every row is N/A: there is no routing, VCS/PR automation or file classification. The only process boundary is `hyprctl` with an argv list (no shell). `dspExpr` rejects names that do not match `^[a-z_]+(\.[a-z_]+)*$` and escapes Lua string arguments. RED tests: injection strings such as `"); hl.dsp.exit() --` and an invalid name.

## Migration / Rollout

No migration. Six chained PRs off `feat/notch-foundation`, each one passing `make check`:
1. `centerState` core and tests (~350 lines)
2. Mid-flow rules and `centerView` (~350 lines)
3. `earGeometry` and `surfaceLayout` (~300 lines)
4. `palette`, `hyprDsp`, `config/`, `services/` (~350 lines)
5. Surface components, placeholders, `shell.qml` (~350 lines)
6. `CenterStore`, `CenterSurface`, idle placeholder (~250 lines)

## Open Questions

- [ ] Does `colors.json` expose dark-scheme values when the system is in light mode? If not, `Colours` needs a `matugen --dry-run --mode dark` source (phase 7).
- [ ] When the launcher is open and power opens, does power replace the launcher or stack on it? The design assumes replace. The spec's scenarios take precedence, and the slot can become a stack if they require it.
- [ ] Does a `PathSvg` path have to be rebuilt every frame while it animates? To be checked manually; fallback is to animate only the width.

# Tasks: Notch foundation

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1,950 (6 slices of 250-350) |
| 400-line budget risk | High as one PR, Low per slice |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 -> PR 2 -> PR 3 -> PR 4 -> PR 5 -> PR 6 |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

Chain choice (stacked-to-main vs feature-branch-chain off `feat/notch-foundation`) must be made before apply. Design assumes the feature-branch chain.

### Suggested Work Units

| Unit | Goal | PR | Focused test | Runtime harness | Rollback |
|---|---|---|---|---|---|
| 1 | Reducer core | 1 | `node --test tests/centerState.test.mjs` | N/A, pure logic | `centerState` + test |
| 2 | Mid-flow rules, view | 2 | `node --test tests/centerState.test.mjs tests/centerView.test.mjs` | N/A | rule edits + `centerView` |
| 3 | Geometry, layout | 3 | `node --test tests/earGeometry.test.mjs tests/surfaceLayout.test.mjs` | N/A | two logic files |
| 4 | Palette, dispatch, tokens, services | 4 | `node --test tests/palette.test.mjs tests/hyprDsp.test.mjs` | `make smoke` | `config/`, `services/` |
| 5 | Surface components, shell.qml | 5 | `make check` | `NOTCH_SMOKE=1 make smoke`; `qs -c notch` with `showPlaceholders` | `components/`, `notches/*`, `shell.qml` |
| 6 | Store, centre surface | 6 | `make check` | `qs -c notch` on 2 monitors | `notches/center/` |

Vocabulary (design wins; mode is derived by `viewFor`): spec `powerMenu`=`power`, `unread`=`blinkDot`, `criticalIndicator`=`showCriticalIndicator`, `holding`=`hold!=null`, `toastPaused`=`toastHovered`. `hoverEnter/Leave`=`Hover{on}`. Spec "Owner change" and "Non-owner ignored" are tested as: an open on another monitor while `keyboard.owner` is set leaves the owner unchanged.

## Phase 1: Reducer core (PR 1)

- [x] 1.1 RED `tests/centerState.test.mjs`: purity (no input mutation, deep-equal), `initialState`, Hover on A only, leave, ExpandedToggle (spec: Purity, Initial, Hover)
- [x] 1.2 GREEN `shell/logic/centerState.mjs`: `initialState`, `reduce`, Hover, ExpandedToggle, ScreensChanged add
- [x] 1.3 RED+GREEN keyboard slot: LauncherToggle, PowerOpen replaces launcher, Close, non-owner open ignored, owner stays
- [x] 1.4 RED+GREEN toast lifecycle: ToastShown, ToastTimeout, ToastDismissed, normal toast timeout, critical goes to `indicator`
- [x] 1.5 REFACTOR; run `node --test tests/`

## Phase 2: Mid-flow rules and view (PR 2)

- [x] 2.1 RED: PolkitRequest clears hold; PolkitEnded/PolkitCancel; `polkit.cancel` effect; HoldStart/Cancel/Complete emits `power.run`
- [x] 2.2 RED: `Locked{on}` closes keyboard, clears hover and pinned, emits `polkit.cancel`; opens ignored while locked
- [x] 2.3 RED: ScreensChanged removal of the owner monitor closes keyboard or cancels polkit; other monitor removal is harmless
- [x] 2.4 RED: suppression (Dnd non-critical sets `blinkDot`; critical bypasses; open keyboard or polkit mutes all monitors)
- [x] 2.5 GREEN: add the rules in `shell/logic/centerState.mjs`
- [x] 2.6 RED `tests/centerView.test.mjs`: priority Polkit > Power > Launcher > Toast > Expanded > Idle; return to previous mode; toast returns to expanded while hovered; critical indicator; `keyboardFocus`
- [x] 2.7 GREEN `shell/logic/centerView.mjs` `viewFor`

## Phase 3: Geometry and layout (PR 3)

- [x] 3.1 RED `tests/earGeometry.test.mjs`: `earCubic` port, `notchPath`, `cornerPath` for all four anchors
- [x] 3.2 GREEN `shell/logic/earGeometry.mjs`
- [x] 3.3 RED `tests/surfaceLayout.test.mjs`: slots never overlap; narrow screen caps centre width
- [x] 3.4 GREEN `shell/logic/surfaceLayout.mjs`

## Phase 4: Palette, dispatch, tokens, services (PR 4)

- [x] 4.1 RED `tests/palette.test.mjs`: valid JSON, missing or invalid input returns null
- [x] 4.2 GREEN `shell/logic/palette.mjs`
- [x] 4.3 RED `tests/hyprDsp.test.mjs`: valid name; invalid name returns null; injection `"); hl.dsp.exit() --` is escaped or rejected
- [x] 4.4 GREEN `shell/logic/hyprDsp.mjs`
- [ ] 4.5 `shell/config/{Fonts,Timings,Layout,Colours,Strings,Flags}.qml` + `qmldir`; `Colours.paletteFor` falls back to a defined palette
- [ ] 4.6 `shell/services/{Session,Hypr}.qml` + `qmldir`; `Hypr.dispatch` returns a boolean and is inert under smoke; `make check`

## Phase 5: Surfaces and shell (PR 5)

- [ ] 5.1 `shell/components/{NotchSurface,SpacerSurface,NotchEarShape,CornerEarShape,NotchZone,Anim}.qml` + `qmldir`
- [ ] 5.2 `shell/notches/{workspaces,osd,controlcenter}` placeholders + `qmldir`
- [ ] 5.3 Rewrite `shell/shell.qml` as a `Scope`; delete `.gitkeep` files; grep finds no `Visibilities` and no `hl.dsp` outside `Hypr`; `make check`

## Phase 6: Store and centre (PR 6)

- [ ] 6.1 `shell/notches/center/CenterStore.qml`: singleton wiring screens, `Session.locked` and effects
- [ ] 6.2 `CenterSurface.qml` and `CenterIdle.qml` (`#000`, strings token); `NotchZone` hover is debounced
- [ ] 6.3 Run `make check`; manual: ears, click-through, hot-plug on 2 monitors

# Plan: Quickshell notch shell

- Status: approved (plan-review-1 and plan-review-2 resolved; handed off to SDD in phases, see "Implementation phases")
- Deadline: none (personal project). Priority = "what is needed to replace the bar for daily use"
- Mode: solo
- Supersedes: the old bar-based config (terminal-like design) and its paused `modules/notch` attempt

## Platforms

| Target | In v1? | Min version / form factor | Distribution |
|---|---|---|---|
| Arch Linux + Hyprland + Quickshell | yes | Current Hyprland build with the Lua dispatch bridge (`hl.dsp.*`); laptop with OLED panel + external monitors | User's dotfiles repo (stow-style) |

- Out of scope: other distros, other compositors (Sway, niri, KDE), X11.

## Research

- Reference 1: saneAspect, "I Replaced My Whole Hyprland Bar With One Notch" (youtu.be/nKomstQedmE). Source of the expanded layout (media left, clock + week strip right). Subtitles were not retrievable (HTTP 429); the design was taken from a user screenshot. (v1)
- Reference 2: vyeos/dotarch (github.com/vyeos/dotarch). A simpler flat `Notch.qml` plus panels. Used for orientation only. (v1)
- Old config inventory (`~/Mio/Configuraciones/dotfiles/quickshell/.config/quickshell`): see "Reuse map" under Core model. (v1)

## Product vision

- **v1:** A minimalist top-edge shell made of notches that look like part of the screen bezel. It replaces the bar entirely. It also takes over what the old shell did besides the bar: wallpaper rendering (incl. video), the caffeine inhibitor, the system tray and the lock screen. It shows only what matters at rest (date, time, CPU/RAM, charging or low battery) and expands on demand: hover for media/calendar, keyboard for the launcher and power menu, the corner for the control center. It reacts to events (workspace changes, app opens, notifications, volume/brightness) with short-lived reveals.
- **v2:** Native WiFi/Bluetooth pages, calendar events (khal + vdirsyncer), brightness right-click action, fixing the laptop power button so it opens the power menu.

## Core model

```
Surfaces (one set per monitor, each with its own input mask)
  BG  background     wallpaper (image/video) + caffeine IdleInhibitor (always mapped, Background layer)
  SP  spacer         invisible; the ONLY surface with exclusiveZone = idle height (when `reserveSpace`)
                     every other top surface uses ExclusionMode.Ignore (zones stack otherwise)
  TL  workspaces     hidden | revealed (timeout) | pinned while a special workspace is active
  BL  brightness OSD hidden | revealed on change (timeout, hover keeps open)
  C   main notch     state machine (below)
  VR  volume OSD     hidden | revealed on change (timeout, hover keeps open)
  TR  control center collapsed | root | subpage(notifications, ...)

Main notch state priority (highest wins)
  Polkit > PowerMenu > Launcher(apps | commands | commandView) > Toast > Expanded(hover) > Idle
  Overlays (not states): charging layer (while plugged), low-battery layer (< 20%, unplugged),
                         unread dot, event glow
  Instances: ONE reducer per monitor, fed by global inputs (notification queue, DND,
  lock state, keyboardOwner = monitor name). Global: toast queue, suppression, dismiss/seen
  state (dismiss on one monitor dismisses everywhere; launcher open on A mutes toasts on all).
  Per monitor: hover, Expanded, which surface shows a keyboard state.
  Mid-flow rules: preemption cancels an in-progress power hold; a polkit flow cancelled
  externally (null flow) returns to the previous state; hovering a visible toast always
  expands the toast; a critical toast collapses after its first timeout into a persistent
  `!` indicator (unread-dot style) so Expanded is reachable again, and stays in the control
  center list until dismissed; on session lock every state closes and polkit is cancelled;
  keyboard states stay on the monitor where they opened; when that screen is removed the
  keyboard state closes and polkit is cancelled.
  Overlay: recording dot (red) on the idle notch while recording.

Key events
  workspace, activespecial, openwindow, movewindowv2, closewindow (Hyprland)
  pluggedIn / unplugged / full (Battery)
  volumeChanged / muteChanged (Pipewire), brightnessChanged (udev)
  notificationReceived / dismissed / seen (Notifs)
  polkitRequest (PolkitAgent), lockRequested (Session)
  IPC (`qs -c notch ipc call <target> <fn>`): launcher, power, lock, caffeine,
       controlcenter (open root | notifications subpage), expanded (toggle)
  Keybinds after cutover: Super+D -> controlcenter root, Super+N -> notifications subpage,
       Super+Alt+C -> expanded toggle (focused monitor)
```

**Reuse map** (from the old config)

| Keep as is or nearly | Rewrite |
|---|---|
| Time, SysInfo, Brightness, BatteryProfile, Recorder, Polkit, Keybinds, Colours/ColoursEngine/Wallpapers, Background/BackgroundSurface (wallpaper + IdleInhibitor) | Notifs/NotifData (no `tracked`, no actions, no real dismiss) |
| **Keep with adapter** (they call `Visibilities`): IdleManager, PowerActions, Lock module -> new `Session` singleton (`lockRequested` signal, `locked` flag) | Battery -> `Quickshell.Services.UPower` (no udevadm/bash forks) |
| Lock transitive deps: LockConfig, LockLayouts, LockLanguages, Security, OsInfo, Paths (token for the hardcoded `quickshell/deadlock` path), vkeyboard assets + `QML_IMPORT_PATH` env. `Style.*` inside the lock is exempt from the tokens rule until it is restyled | SystemTray host (old BgAppsWidget/TrayMenuOsd as reference) |
| EarCurve.js, NotchEarShape, NotchDropdown, NotchZone, ArcMeter, Anim/CAnim, StateLayer, MoveGuard | Audio (move to `Quickshell.Services.Pipewire`) |
| Special-workspace raw-event tracking, workspace probing, launcher command list + prefix parser, CalendarCard grid, MediaSection ticker | Battery (separate plugged/charging/full), Mpris (drop the 1s poll), Visibilities (replaced by state machine), list-apps.py (use DesktopEntries), CornerEarShape (generalize beyond topLeft), Bluetooth/Network (v2) |

## Foundation

Done. See [architecture](../../architecture.md), [development setup](../../development.md), [AGENTS.md](../../../AGENTS.md) and ADRs [0001 repo + symlink](../../adr/0001-separate-repo-and-symlink.md), [0002 layout](../../adr/0002-hybrid-layout-pure-logic.md), [0003 testing](../../adr/0003-testing-strategy.md), [0004 surfaces + input](../../adr/0004-layer-surfaces-and-input.md), [0005 visual tokens](../../adr/0005-visual-tokens.md).

- Own GitHub repo; run with `qs -p shell/shell.qml` until cutover (`~/.config/quickshell` is a stow link into the dotfiles, so no `notch` symlink yet; ADR 0001 update); the old bar stays as fallback.
- Layout: `config/` tokens, `services/` data singletons, `logic/` pure `.mjs`, `components/`, `notches/{center,workspaces,osd,controlcenter}/`; `qmldir` per folder.
- Strict TDD with `node --test` on `logic/`; smoke run with `qs -p`; UI verified manually. `make check` = format, lint, tests, smoke.
- Per-monitor fixed-size `PanelWindow`s with mandatory input masks; exclusive zone = idle height (`reserveSpace` toggle).
- Pure `#000` notches, matugen dark-scheme accents, IosevkaTerm Nerd Font defined once.

## Screens

### Main notch: idle + charging

```
 idle
        ╭──────────────────────────────╮
        │  (◔)  Mar 20 · 14:32  (◑)  • │
        ╰──────────────────────────────╯
 charging (grows equally on both sides; the clock never moves)
  ╭──────────────────────────────────────────╮
  │ ⚡▮▮▮▯  (◔)  Mar 20 · 14:32  (◑)   72%  │
  ╰──────────────────────────────────────────╯
 low battery (< 20%, unplugged; same symmetric layout, red)
  ╭──────────────────────────────────────────╮
  │ ▮▯▯▯▯   (◔)  Mar 20 · 14:32  (◑)   18%  │   + slow red glow pulse every ~30s
  ╰──────────────────────────────────────────╯
```

- Chosen: A (symmetric) with C's date, date before time; charging = symmetric growth, battery icon left, percentage right. Low battery mirrors the charging layer in red.
- Rules: `(◔)`/`(◑)` = CPU/RAM ring with the icon inside. The unread dot sits in the right padding and does not change the width. Plug-in triggers the charge animation + a glow pulse. Below 20% unplugged: low-battery layer + a slow red "breathing" glow pulse every ~30s (intermittent, not permanent: OLED burn-in). At 10%: one critical toast (stays until dismissed). Plugging in replaces the low-battery layer with the charging one.
- States: no battery -> no battery layers | plugged & full -> full icon + 100%, no animation | 20-100% unplugged -> no battery layer.
- OLED: the idle content shifts 1 px every few minutes (invisible pixel shift; SHOULD).
- Recording: a small red dot overlay on the idle notch while recording (v1). The user plans to expand this indicator later (richer recording UI: elapsed time, stop control, etc.; design TBD in its own mini-plan).

| UI element | Backend demand |
|---|---|
| date · time | `Time` |
| rings | `SysInfo.cpu/ram` |
| charging layer | `Battery.present/plugged/charging/full`, `pluggedIn` edge event (UPower) |
| low-battery layer | `Battery.percentage`, thresholds 20/10 as config tokens, one-shot critical toast |
| unread dot | `Notifs.unreadCount` |

### Main notch: expanded (hover)

```
╭──────────────────────────────────────────────────────╮
│ ┌──────┐ Song title                 ╭──────────────╮ │
│ │ art  │ Album                      │    23:48     │ │
│ │      │ ARTIST                     │ ·· T F [S] S M ·· │
│ └──────┘   ⏮   ⏯   ⏭                │   30 31 [1] 2 3   │
│                                     ╰──────────────╯ │
╰──────────────────────────────────────────────────────╯
```

- Chosen: layout from the saneAspect screenshot.
- Rules: the week strip is centred on today, ±3 days (config token). Replaces the idle row (rings hidden while expanded). Open delay ~200ms, close delay debounced. Click the calendar card -> full month replaces the media column (back returns). Scroll navigates weeks/months; click the clock -> today.
- States: no player -> only the clock+week card, narrower notch | no art -> generic icon | several players -> the one playing.

| UI element | Backend demand |
|---|---|
| media | `Mpris` (reactive, no poll), `hasPlayer` |
| week/month | CalendarCard grid + offset navigation, midnight rollover |

### Main notch: notification toast

```
╭──────────────────────────────╮    hover    ╭────────────────────────────────────╮
│ [ico] Discord: Juan: ¿jugam… │   ───────►  │ [ico] Discord · now             ✕  │
╰──────────────────────────────╯             │       Juan: ¿jugamos hoy?          │
                                             │   [ Open ]  [ Later ]              │
                                             ╰────────────────────────────────────╯
```

- Chosen: C (compact, expands on hover).
- Rules: one at a time, newest first, `+N` if queued. Timeout paused on hover. Critical urgency stays until dismissed. Click body = default action. Preempts Expanded and returns to it if still hovered. A primary-colour glow pulse on arrival. After it hides, the unread dot stays.
- Buttons are the notification's own DBus actions; no inline reply in v1 (`inlineReplySupported: false`). The queue is keyed by notification id; an update to a tracked notification (`replaces-id`) refreshes the toast. History is session-only, capped at 50 (oldest dropped).
- Buttons in the mockup are example DBus actions; the only local control is ✕ (dismiss).
- Critical urgency and the shell's 10% battery toast bypass DND (covered by queue tests).
- Suppression: DND -> no toast, the dot still appears. Launcher/power/polkit open -> no toast, blinking dot in the launcher corner.

| UI element | Backend demand |
|---|---|
| actions, ✕ | `Notifs` rewrite: `tracked = true`, actions, real DBus dismiss |
| queue, +N | single queue timer, `replaces-id` handling |
| DND, unread | `dnd` flag, history list, `unreadCount`, `markSeen()` |

### Workspaces notch (top-left corner)

```
 normal (reveals on change, then hides)       on app open               special active (pinned)
╭─────────────────────────╮    ╭─────────────────────────╮      ╭──────────╮
│    –   ●     –   │    │    –  []   –   │      │   │ 󰎆   │
╰─────────────────────────╯    ╰─────────────────────────╯      ╰──────────╯
```

- Chosen: A (dots) mixed with C (app icons).
- Rules: ● = active, – = empty, app icon = occupied but inactive (the last-focused app there, fallback ○). Triggers: workspace change, window open (the active slot shows the new app icon for a few seconds), window moved (the icon flies from source to destination slot; SHOULD). Only normal toplevel windows count (dialogs, popups and transient floats are ignored), with a short debounce. Moving to a special -> the icon fades out. Concave ears to the top and left screen edges.
- Per monitor: each monitor's notch shows the workspaces bound to that monitor; the slot count is a config token (default = the old widget's `maxVisible`).
- States: special active -> pinned, showing only Arch + special icon.

| UI element | Backend demand |
|---|---|
| occupancy + icon | per-workspace windows + `focusHistoryID`; class -> DesktopEntries icon |
| triggers | Hyprland events: workspace, activespecial, openwindow, movewindowv2, closewindow |
| fly animation | own window -> workspace map (move events only give the destination) |

### Volume / brightness OSD

```
╭──────────────────────────────╮          ╭──────────────────────────────╮
│  ━━━━━━━━━━(󰕾)──────────  62 │  muted → │  ┄┄┄┄┄┄┄┄┄┄(󰝟)┄┄┄┄┄┄┄┄┄┄  62 │
╰──────────────────────────────╯          ╰──────────────────────────────╯
```

- Chosen: A (bar), with the icon inside the thumb.
- Rules: volume sits between the centre and TR, brightness between TL and the centre (mirrored). Reveals on value change; hover keeps it open; drag and scroll adjust. Volume right-click = toggle mute. Brightness right-click = nothing (v1).
- States: muted -> dimmed track + muted icon.

| UI element | Backend demand |
|---|---|
| volume | `Audio` on Pipewire: reactive volume/mute, `toggleMute()` |
| brightness | `Brightness` (udev) |
| slider | one shared slider component |

### Control center (top-right corner)

```
╭────────────────────────────────╮
│ (avatar) user                   │
│          up 3h 12m              │
│  󰌾    󰤄    󰍃    󰜉    ⏻          │
│ ────────────────────────────── │
│ [󰖩 WiFi] [󰂯 BT] [󰂛 DND]          │
│ [󰾆 Profile] [󰅶 Caffeine] [󰑊 Rec] │
│ ────────────────────────────── │
│ Tray:  󰙯  󰓓  󰍡                   │
│ ────────────────────────────── │
│ Notifications (5)        Clear │
│ [ico] Discord: Juan: ¿jug…     │
│ [ico] Steam: Update ready      │
│ [ico] Mail: New message        │
│                  See all ›     │
╰────────────────────────────────╯
```

- Chosen: profile header from the old config + tile grid (A) + inline notifications (C).
- Rules: opens on hover with a ~200ms activation delay and a small hot zone. Tiles: left click toggles, right click opens the subpage. WiFi/BT right click opens impala/bluetui in a terminal (v1). DND right click and "See all" open the notifications subpage. At most 3 inline notifications. Power row: lock/suspend run directly; logout/reboot/shutdown open the power menu with that action preselected. Inside a subpage the panel does not collapse on a brief mouse leave (Esc, click outside or a longer delay closes it). Only opening the notifications subpage marks notifications as seen (clears the dot); hovering the root does not.
- Tray row: compact icon row of StatusNotifierItems; left click = activate (restore the app), right click = the item's menu. Hidden when empty.
- Subpage "Notifications": back button + the full history list (same item style as inline), per-item dismiss, Clear all, DND toggle. Derived; no variants shown.
- States: no notifications -> "No notifications" line, no list.

| UI element | Backend demand |
|---|---|
| profile | user name/avatar, `OsInfo.uptime` |
| tiles | WiFi radio via `rfkill` (state read without root), BT power via `Quickshell.Bluetooth`, `Notifs.dnd`, `BatteryProfile`, `IdleManager.caffeineMode` (inhibitor lives on the BG surface), `Recorder` |
| tray | `Quickshell.Services.SystemTray` items + menus |
| navigation | control center stack (root -> subpage) |

### Power menu (main notch state)

```
╭──────────────────────────────────────────╮
│    󰌾      󰤄      󰍃     [󰜉]     ⏻          │
│          hold Enter  ▓▓▓▓░░░             │
╰──────────────────────────────────────────╯
```

- Chosen: C (hold to confirm).
- Rules: opens with Ctrl+Alt+Del (IPC) or from the control center (with the action preselected). Arrows/hjkl move, Esc closes. Lock/suspend fire immediately; logout/reboot/shutdown need ~1s hold (Enter or mouse press) with a progress bar, and releasing early cancels. Key auto-repeat events are ignored; progress is driven by a timer started on the first press. Exclusive keyboard focus only while open.

| UI element | Backend demand |
|---|---|
| actions | `PowerActions` |
| open | IPC `power` + optional preselected action |

### Launcher (main notch state)

```
 apps                                   commands (">")
╭────────────────────────────────╮     ╭─────────────────────────────────────────────╮
│ 󰍉 fire▏                     •  │     │ 󰍉 >▏                                     •  │
│ ────────────────────────────── │     │ ▸󰸉 Wallpaper      │ Choose the desktop      │
│ ▸󰈹 Firefox       Web browser   │     │  󰏘 Theme          │ wallpaper. Notch colours│
│  󰉋 Files                       │     │  󰌌 Keybinds       │ follow it.  Enter → open│
╰────────────────────────────────╯     ╰─────────────────────────────────────────────╯
```

- Chosen: A for apps, C for commands with a description pane instead of previews.
- Rules: Enter on a command switches the notch to that command's view (ports the old functionality with the new style). v1 MUST: wallpaper, theme, keybinds. SHOULD: screensaver, security, webapp. Wallpaper changes are rendered by the BG surface and also applied to hyprpaper as a fallback. Apps launch through `DesktopEntry.execute()` / the single `Hypr` dispatch wrapper. Esc goes back one level. The blinking dot appears when a notification arrives.
- States: no results -> "No matches" line.

| UI element | Backend demand |
|---|---|
| apps | `DesktopEntries` + ranked fuzzy search |
| commands | reuse the list + prefix parser; add `description` |

### Polkit (main notch state)

- Derived: the notch expands with the requesting action message + a password field + Cancel/Authenticate. Highest priority; exclusive focus. Reuses the `Polkit` service. No variants shown.

## Visual style

- Notch background: pure `#000`, opaque (bezel illusion on OLED).
- Inner cards: black mixed with 6-10% of matugen `primary`.
- Accents (rings, slider, active tile, ● workspace, unread dot): matugen **dark-scheme** `primary`, always, **per monitor** (each monitor's notches use the palette of that monitor's wallpaper; `Colours.paletteFor(screen)`).
- Text: dark-scheme `on_surface` + a muted variant.
- No permanent glow/shadow (it would break the illusion, risk OLED burn-in and reintroduce MultiEffect artifacts). Glow only as event feedback: plug-in (~1s, accent), notification arrival (primary), low battery (red, slow pulse every ~30s while < 20%).
- Max centre-notch width is a token per monitor so expanded states never overlap the OSD/corner surfaces on narrow monitors.
- Concave ears (EarCurve.js) wherever a notch meets a screen edge.
- Font: IosevkaTerm Nerd Font, defined once in the config tokens.

## Data captured / data inventory

| Screen | Data shown | Actions (events) | Source |
|---|---|---|---|
| Idle | date, time, CPU %, RAM %, battery % (only while charging or < 20%), unread | hover | Time, SysInfo, Battery, Notifs |
| Background | wallpaper image/video | (none; set by the wallpaper command) | Wallpapers |
| Expanded | track, art, week/month | play/pause/next/prev, open month, scroll, today | Mpris, Time |
| Toast | app, summary, body, actions | action, dismiss, default action | Notifs |
| Workspaces | occupancy, active, app icons, special | (display only) | Hyprland, DesktopEntries |
| OSD | volume/brightness % | drag, scroll, mute | Audio, Brightness |
| Control center | profile, uptime, tile states, tray items, notifications | toggles, subpages, power, tray activate/menu, clear | OsInfo, services, SystemTray, Notifs |
| Power menu | actions | select, hold-confirm | PowerActions |
| Launcher | apps, commands, descriptions | search, launch, open command | DesktopEntries, commands |
| Polkit | message, password | authenticate, cancel | Polkit |

## Scope

| Item | Priority | Est. dev-days | Demo value |
|---|---|---|---|
| Shell skeleton: per-monitor surfaces, single spacer exclusive zone, input masks, ears (incl. CornerEarShape generalisation), tokens, `NOTCH_SMOKE` mode | MUST | 3 | foundation |
| Service rewrites: Battery (UPower), Audio (Pipewire), Notifs (tracked, id-keyed, cap 50), Mpris (reactive), `Session` adapter, `Hypr` dispatch wrapper, one-time state import | MUST | 4.25 | foundation |
| Background surface (image/video wallpaper) + caffeine IdleInhibitor (reuse) + hyprpaper fallback | MUST | 1 | high |
| Hyprland cutover: exec `qs -c notch` + env, IPC names, keybind remap, root-owned sleep hook (`lock-before-sleep`), rollback script, suspend-locks checklist | MUST | 0.75 | foundation |
| Main notch idle (rings, date/time, unread dot) + low-battery layer + 10% critical toast + recording dot | MUST | 1.75 | high |
| Main notch state machine (per-monitor instances, global inputs, priorities, preemption, mid-flow, critical `!` rule, screen removal) | MUST | 2.5 | foundation |
| Workspaces notch (dots, icons, triggers, special pin) | MUST | 3 | high |
| Volume/brightness OSDs | MUST | 1.5 | high |
| Notification toast + DND + unread | MUST | 2 | high |
| Launcher apps + commands + description pane | MUST | 2.5 | high |
| Command views: wallpaper, theme, keybinds | MUST | 2.5 | medium |
| Power menu with hold-confirm + Ctrl+Alt+Del | MUST | 1 | medium |
| Polkit state | MUST | 0.5 | medium |
| Control center root + tiles + notifications subpage | MUST | 3 | high |
| System tray row in the control center | MUST | 1.5 | high |
| Lock module integration (with deps + `Session` adapter) | MUST | 1.5 | medium |
| Expanded hover: media + week strip | MUST | 1.5 | high |
| Charging layer + animation + glow pulse | SHOULD | 1 | high |
| Low-battery red breathing glow | SHOULD | 0.25 | medium |
| Command views: screensaver, security, webapp | SHOULD | 2 | medium |
| Workspace fly animation on window move | SHOULD | 1 | medium |
| Calendar month view, scroll, back to today | SHOULD | 1 | medium |
| Notification glow pulse | SHOULD | 0.25 | low |
| OLED pixel shift of the idle content | SHOULD | 0.25 | low |
| Native WiFi/BT pages | LATER | 3 | medium |
| Calendar events (khal + vdirsyncer) | LATER | 2 | medium |
| Laptop power button -> power menu | LATER | 0.5 | low |

## Demo data

- `test-notif.sh`-style script with `notify-send` covering normal, critical, with actions, replacing (same id) and burst (5 in a row).
- Low battery: a `Battery` override token (dev only) to force a percentage, since draining to 20% is slow.
- Manual: plug/unplug the charger, `wpctl`/`brightnessctl` keybinds, open/move windows across workspaces, toggle a special workspace, `pkexec true` for polkit.

## Data gaps & assumptions

| Gap | Assumption | Owner | Resolved? |
|---|---|---|---|
| Font | IosevkaTerm Nerd Font, defined in ONE token (single place to swap it) | user | yes |
| Multi-monitor | Passive notches (idle, workspaces, OSDs, toasts) on every monitor; keyboard states (launcher, power, polkit) only on the focused monitor | user | yes |
| Command views design (wallpaper, theme, screensaver, security, keybinds, webapp) | Functionality = the old config's; each view's UI is designed in its own mini-plan right before its implementation phase | user | deferred |
| WiFi tile toggle backend | Tile toggles the radio from the control center (no hardware key); implemented with `rfkill` / iwd power | Claude | yes |
| Timings (hover delay, reveal timeout, animation durations, hold-confirm) | Centralized tokens in one place (hover open 200ms, reveal ~1.5s, hold ~1s); tuned during implementation | Claude | yes |
| Icon resolution for odd window classes | Fallback = first letter of the app name (like the old config) | user | yes |
| Reserved space vs overlay | Reserve the idle notch height (exclusive zone) by default; expanded states overlay windows temporarily; `reserveSpace` toggle in config. The strip beside the notches shows the wallpaper (not painted black) | user | yes |
| saneAspect video details beyond the screenshot | Not retrievable; only the screenshot is used | — | yes |
| State files | Own state dir `~/.local/state/quickshell-notch/`; on first run import the old config's values (idle, wallpaper, theme, security); never write to the old dir | Claude | yes |
| Running both configs | Never run the old and new shells at once (notification DBus name, polkit agent, idle locking). The cutover/rollback script stops one before starting the other | Claude | yes |
| Smoke test on the live session | `make smoke` sets `NOTCH_SMOKE=1`: no NotificationServer, PolkitAgent, IdleMonitors, IpcHandlers, exclusive zone, BG surface, or state import/writes | Claude | yes |
| WiFi toggle without root | `rfkill` state is readable via `/dev/rfkill` (uaccess); check `rfkill block wlan` as the user in phase 1; fallback = iwd DBus `Powered` | Claude | no |
| Sleep hook | `/usr/lib/systemd/system-sleep/lock-before-sleep` is root-owned and calls the default config. Cutover edits it (sudo, user-approved) to call `qs -c notch ipc call lock lock`, falling back to the default config so rollback keeps locking. Verified with one `systemctl suspend` | Claude | yes |
| Video while locked | BG video pauses while `Session.locked` (the lock surface may play its own video) | Claude | yes |

## Deferred to v2

- Native WiFi/BT subpages (scan, connect, password) — high cost; v1 opens impala/bluetui.
- Calendar events — needs a data source (khal + vdirsyncer).
- Brightness right-click action — no clear use yet.
- Laptop power button binding — a separate diagnosis (logind `HandlePowerKey` / `libinput debug-events`). Note: `keybinds.lua` already binds `XF86PowerOff` to the lock IPC, so check whether the key event reaches Hyprland at all.
- Notification history across restarts — session-only by decision.
- UI following the system locale — far future.
- Weather tab (old wttr.in panel) — deferred to v2.
- Full-shell parity after the notch is done: a lockscreen redesigned in the notch style (v1 only reuses the old lock as is), the screensaver, and other remaining pieces of the old config, so the new config fully replaces it. Each gets its own plan/mini-plan.
- Expanded recording indicator (elapsed time, stop control, ...) — the user will expand the v1 red dot later; own mini-plan.

## Demo priorities

1. Idle notch at rest + hover expand with media + week (replaces the old bar's clock/calendar/media).
2. Workspace notch reacting to switching and opening apps (fly animation when SHOULD lands).
3. Charging plug-in animation and low-battery state (SHOULD polish).
4. Notification toast -> unread dot -> control center list.
5. Launcher apps + commands; power menu hold-confirm.

## Implementation phases

One SDD change per phase, in order. Each phase ends with `make check` green and something visible with `qs -p shell/shell.qml`. The old bar stays the daily shell until phase 7 (cutover).

| # | SDD change | Scope (MUST rows) | Est. dev-days |
|---|---|---|---|
| 1 | `notch-foundation` | Shell skeleton (surfaces per monitor, spacer zone, masks, ears, tokens, `NOTCH_SMOKE`), `Session`, `Hypr` wrapper, centre state machine reducer (pure logic, per-monitor + global inputs, mid-flow rules) | 6.25 |
| 2 | `notch-center` | Battery (UPower), Mpris, SysInfo/Time reuse; idle notch + low-battery layer + 10% toast hook + recording dot; expanded hover (media + week) | 4.25 |
| 3 | `notch-workspaces-osd` | Workspaces notch; Audio (Pipewire); volume/brightness OSDs | 5.25 |
| 4 | `notch-notifications` | Notifs rewrite (tracked, id-keyed, cap 50, DND, critical `!`); toast + unread dot | 3.5 |
| 5 | `notch-control-center` | Control center root, tiles (rfkill/BT checks first), tray row, notifications subpage | 4.5 |
| 6 | `notch-launcher-power` | Launcher apps + commands; wallpaper/theme/keybinds views; power menu; polkit | 6.5 |
| 7 | `notch-cutover` | Background surface + IdleInhibitor + hyprpaper fallback; lock integration; state import; Hyprland cutover (exec, env, IPC, keybinds, sleep hook, rollback) | 3.5 |
| 8+ | `notch-polish-*` | SHOULD items in the Scope order | 5.75 |

Phases 1-7 = 33.75 dev-days (the MUST total).

Superseded: the old bar config and its paused `modules/notch` attempt (reuse only per the reuse map). No earlier proposal/specs exist.

## Collaboration

- Mode: solo
- People: n/a
- Frozen contracts: n/a
- Work packages: n/a

## Plan-review resolutions

| # | Finding | Resolution | Decided by |
|---|---|---|---|
| R1-1 | IdleManager/PowerActions/Lock depend on `Visibilities` | Keep with adapter: new `Session` singleton (`lockRequested`, `locked`); reuse map updated | planner |
| R1-2 | No background surface (video wallpaper, caffeine inhibitor) | BG surface reuses old Background/BackgroundSurface + IdleInhibitor; wallpaper changes also set hyprpaper as fallback. MUST, 1d | user |
| R1-3 | Exclusive zones stack between top surfaces | One invisible spacer per monitor owns the zone; all other top surfaces use `ExclusionMode.Ignore`; ADR 0004 updated | planner |
| R1-4 | No Hyprland cutover | MUST item: exec `qs -c notch` + `QML_IMPORT_PATH`, `qs -c notch ipc call`, IPC targets launcher/power/lock/caffeine/controlcenter, rollback script. 0.5d | planner |
| R1-5 | No system tray | MUST: compact tray row in the control center (activate + menu). 1.5d | user |
| R1-6 | No battery while discharging / low-battery warning | Low-battery layer below 20% (mirror of charging, red), slow red breathing glow every ~30s, critical toast at 10% | user |
| R1-7 | Lock integration underestimated | Re-estimated 1.5d; transitive deps listed in the reuse map; `Style.*` inside the lock exempt until restyled | planner |
| R1-8 | Command views underestimated | Wallpaper/theme/keybinds MUST (2.5d); screensaver/security/webapp SHOULD (2d) | user |
| R1-9 | Demo priorities vs scope | Expanded hover (media + week) moved to MUST; demo priorities reordered | planner |
| R1-10 | Inline reply vs focus None | Buttons = DBus actions; `inlineReplySupported: false` in v1 | planner |
| R1-11 | Notification history persistence/cap | Session-only, capped at 50 | user |
| R1-12 | Mid-flow cases undefined | Rules added to the core model (preemption cancels hold, null polkit flow returns, critical toast allows Expanded, lock closes all, keyboard states stay on their monitor) | planner |
| R1-13 | Enter auto-repeat breaks hold-to-confirm | Ignore `isAutoRepeat`; timer-driven progress | planner |
| R1-14 | v1 tile state sources | BT via `Quickshell.Bluetooth`; WiFi via `rfkill` (root-less toggle to verify) | planner |
| R1-15 | `replaces-id` updates the tracked object | Queue keyed by id, refresh on property change, covered by logic tests | planner |
| R1-16 | Week strip start day | Centred on today, ±3 days, config token | planner |
| R1-risk | Smoke test on live session; both shells running; shared state; narrow monitors; Lua bridge; OLED burn-in | `NOTCH_SMOKE=1`; never run both (cutover script); own state dir with one-time import; max centre width token; single `Hypr` dispatch wrapper; 1 px pixel shift (SHOULD) | planner |

Source: [plan-review-1.md](plan-review-1.md).

| # | Finding | Resolution | Decided by |
|---|---|---|---|
| R2-1 | Sleep hook still targets the default config (suspend without lock) | Cutover edits the root-owned hook (sudo) to call the notch config with fallback to the default; suspend-locks checklist step | planner |
| R2-2 | Toast hover vs critical toast contradiction | Hover on a visible toast always expands it; critical collapses to a persistent `!` after first timeout, Expanded reachable; stays in the list until dismissed | user + planner |
| R2-3 | Global vs per-monitor state machine | One reducer per monitor with global inputs; queue, suppression and dismiss/seen global; hover/Expanded per monitor | user |
| R2-4 | Workspaces per monitor / slot count | Workspaces bound to each monitor; slot-count token (default old `maxVisible`) | planner |
| R2-5 | "Mark read" vs DBus-only actions | Mockup buttons are example DBus actions; ✕ is the only local control | planner |
| R2-6 | Per-monitor palettes vs single accent | Accents per monitor via `Colours.paletteFor(screen)`; ADR 0005 updated | user |
| R2-7 | Keybinds lose targets | Super+D -> control center, Super+N -> notifications subpage, Super+Alt+C -> new `expanded` toggle IPC | user |
| R2-8 | Weather and recording indicator dropped silently | Weather deferred to v2; red recording dot on the idle notch (MUST), to be expanded later in its own mini-plan | user |
| R2-9 | Seen-marking on accidental hover | Only opening the notifications subpage marks seen | planner |
| R2-10 | DND vs critical / battery toast | Critical and the 10% battery toast bypass DND | user |
| R2-11 | MUST total misadded | Totals recomputed (see below) | planner |
| R2-12 | Smoke mode still maps BG and imports state | `NOTCH_SMOKE` also skips BG surface, state import/writes and IpcHandlers; ADR 0004 updated | planner |
| R2-risk | Hot-plug with keyboard state; smoke receiving IPC; rfkill root; two videos while locked | Screen removal closes keyboard states and cancels polkit; no IpcHandlers in smoke; rfkill checked in phase 1 with iwd fallback; BG video paused while locked | planner |

Source: [plan-review-2.md](plan-review-2.md). MUST total after resolutions: 33.75 dev-days (no deadline; ~7 weeks to daily use).

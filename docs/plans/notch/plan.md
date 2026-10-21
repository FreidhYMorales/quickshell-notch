# Plan: Quickshell notch shell

- Status: draft
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

- **v1:** A minimalist top-edge shell made of notches that look like part of the screen bezel. It replaces the bar entirely. It shows only what matters at rest (date, time, CPU/RAM, charging) and expands on demand: hover for media/calendar, keyboard for the launcher and power menu, the corner for the control center. It reacts to events (workspace changes, app opens, notifications, volume/brightness) with short-lived reveals.
- **v2:** Native WiFi/Bluetooth pages, calendar events (khal + vdirsyncer), brightness right-click action, fixing the laptop power button so it opens the power menu.

## Core model

```
Surfaces (one set per monitor, all on the top edge, each with its own input mask;
          an exclusive zone = idle notch height is reserved, toggle `reserveSpace`)
  TL  workspaces     hidden | revealed (timeout) | pinned while a special workspace is active
  BL  brightness OSD hidden | revealed on change (timeout, hover keeps open)
  C   main notch     state machine (below)
  VR  volume OSD     hidden | revealed on change (timeout, hover keeps open)
  TR  control center collapsed | root | subpage(notifications, ...)

Main notch state priority (highest wins)
  Polkit > PowerMenu > Launcher(apps | commands | commandView) > Toast > Expanded(hover) > Idle
  Overlays (not states): charging layer (while plugged), unread dot, event glow

Key events
  workspace, activespecial, openwindow, movewindowv2, closewindow (Hyprland)
  pluggedIn / unplugged / full (Battery)
  volumeChanged / muteChanged (Pipewire), brightnessChanged (udev)
  notificationReceived / dismissed / seen (Notifs)
  polkitRequest (PolkitAgent), IPC: launcher, power, lock
```

**Reuse map** (from the old config)

| Keep as is or nearly | Rewrite |
|---|---|
| Time, SysInfo, Brightness, BatteryProfile, Recorder, IdleManager, Polkit, Keybinds, PowerActions, Colours/ColoursEngine/Wallpapers, Lock module | Notifs/NotifData (no `tracked`, no actions, no real dismiss) |
| EarCurve.js, NotchEarShape, NotchDropdown, NotchZone, ArcMeter, Anim/CAnim, StateLayer, MoveGuard | Audio (move to `Quickshell.Services.Pipewire`) |
| Special-workspace raw-event tracking, workspace probing, launcher command list + prefix parser, CalendarCard grid, MediaSection ticker | Battery (separate plugged/charging/full), Mpris (drop the 1s poll), Visibilities (replaced by state machine), list-apps.py (use DesktopEntries), CornerEarShape (generalize beyond topLeft), Bluetooth/Network (v2) |

## Foundation

Done. See [architecture](../../architecture.md), [development setup](../../development.md), [AGENTS.md](../../../AGENTS.md) and ADRs [0001 repo + symlink](../../adr/0001-separate-repo-and-symlink.md), [0002 layout](../../adr/0002-hybrid-layout-pure-logic.md), [0003 testing](../../adr/0003-testing-strategy.md), [0004 surfaces + input](../../adr/0004-layer-surfaces-and-input.md), [0005 visual tokens](../../adr/0005-visual-tokens.md).

- Own GitHub repo; `shell/` symlinked to `~/.config/quickshell/notch`, run with `qs -c notch`; the old bar stays as fallback.
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
```

- Chosen: A (symmetric) with C's date, date before time; charging = symmetric growth, battery icon left, percentage right.
- Rules: `(◔)`/`(◑)` = CPU/RAM ring with the icon inside. The unread dot sits in the right padding and does not change the width. Plug-in triggers the charge animation + a glow pulse.
- States: no battery -> no charging layer | plugged & full -> full icon + 100%, no animation.

| UI element | Backend demand |
|---|---|
| date · time | `Time` |
| rings | `SysInfo.cpu/ram` |
| charging layer | `Battery.present/plugged/charging/full`, `pluggedIn` edge event |
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
- Rules: replaces the idle row (rings hidden while expanded). Open delay ~200ms, close delay debounced. Click the calendar card -> full month replaces the media column (back returns). Scroll navigates weeks/months; click the clock -> today.
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
                                             │   [ Reply ]  [ Mark read ]         │
                                             ╰────────────────────────────────────╯
```

- Chosen: C (compact, expands on hover).
- Rules: one at a time, newest first, `+N` if queued. Timeout paused on hover. Critical urgency stays until dismissed. Click body = default action. Preempts Expanded and returns to it if still hovered. A primary-colour glow pulse on arrival. After it hides, the unread dot stays.
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
│ Notifications (5)        Clear │
│ [ico] Discord: Juan: ¿jug…     │
│ [ico] Steam: Update ready      │
│ [ico] Mail: New message        │
│                  See all ›     │
╰────────────────────────────────╯
```

- Chosen: profile header from the old config + tile grid (A) + inline notifications (C).
- Rules: opens on hover with a ~200ms activation delay and a small hot zone. Tiles: left click toggles, right click opens the subpage. WiFi/BT right click opens impala/bluetui in a terminal (v1). DND right click and "See all" open the notifications subpage. At most 3 inline notifications. Power row: lock/suspend run directly; logout/reboot/shutdown open the power menu with that action preselected. Inside a subpage the panel does not collapse on a brief mouse leave (Esc, click outside or a longer delay closes it). Opening the notification list marks notifications as seen (clears the dot).
- Subpage "Notifications": back button + the full history list (same item style as inline), per-item dismiss, Clear all, DND toggle. Derived; no variants shown.
- States: no notifications -> "No notifications" line, no list.

| UI element | Backend demand |
|---|---|
| profile | user name/avatar, `OsInfo.uptime` |
| tiles | WiFi toggle (iwd), BT power, `Notifs.dnd`, `BatteryProfile`, `IdleManager.caffeineMode`, `Recorder` |
| navigation | control center stack (root -> subpage) |

### Power menu (main notch state)

```
╭──────────────────────────────────────────╮
│    󰌾      󰤄      󰍃     [󰜉]     ⏻          │
│          hold Enter  ▓▓▓▓░░░             │
╰──────────────────────────────────────────╯
```

- Chosen: C (hold to confirm).
- Rules: opens with Ctrl+Alt+Del (IPC) or from the control center (with the action preselected). Arrows/hjkl move, Esc closes. Lock/suspend fire immediately; logout/reboot/shutdown need ~1s hold (Enter or mouse press) with a progress bar, and releasing early cancels. Exclusive keyboard focus only while open.

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
- Rules: Enter on a command switches the notch to that command's view (wallpaper, theme, screensaver, security, keybinds, webapp; ports the old functionality with the new style). Esc goes back one level. The blinking dot appears when a notification arrives.
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
- Accents (rings, slider, active tile, ● workspace, unread dot): matugen **dark-scheme** `primary`, always.
- Text: dark-scheme `on_surface` + a muted variant.
- No permanent glow/shadow (it would break the illusion, risk OLED burn-in and reintroduce MultiEffect artifacts). Glow only as event feedback: plug-in (~1s) and notification arrival.
- Concave ears (EarCurve.js) wherever a notch meets a screen edge.
- Font: IosevkaTerm Nerd Font, defined once in the config tokens.

## Data captured / data inventory

| Screen | Data shown | Actions (events) | Source |
|---|---|---|---|
| Idle | date, time, CPU %, RAM %, battery %, unread | hover | Time, SysInfo, Battery, Notifs |
| Expanded | track, art, week/month | play/pause/next/prev, open month, scroll, today | Mpris, Time |
| Toast | app, summary, body, actions | action, dismiss, default action | Notifs |
| Workspaces | occupancy, active, app icons, special | (display only) | Hyprland, DesktopEntries |
| OSD | volume/brightness % | drag, scroll, mute | Audio, Brightness |
| Control center | profile, uptime, tile states, notifications | toggles, subpages, power, clear | OsInfo, services, Notifs |
| Power menu | actions | select, hold-confirm | PowerActions |
| Launcher | apps, commands, descriptions | search, launch, open command | DesktopEntries, commands |
| Polkit | message, password | authenticate, cancel | Polkit |

## Scope

| Item | Priority | Est. dev-days | Demo value |
|---|---|---|---|
| Shell skeleton: per-monitor surfaces, input masks, ears, theming tokens | MUST | 2 | foundation |
| Service rewrites: Battery, Audio (Pipewire), Notifs, Mpris | MUST | 3 | foundation |
| Main notch idle (rings, date/time, unread dot) | MUST | 1 | high |
| Main notch state machine (priorities, preemption) | MUST | 1.5 | foundation |
| Workspaces notch (dots, icons, triggers, special pin) | MUST | 2 | high |
| Volume/brightness OSDs | MUST | 1 | high |
| Notification toast + DND + unread | MUST | 1.5 | high |
| Launcher apps + commands + description pane | MUST | 2 | high |
| Port command views (wallpaper, theme, screensaver, security, keybinds, webapp) | MUST | 2 | medium |
| Power menu with hold-confirm + Ctrl+Alt+Del | MUST | 1 | medium |
| Polkit state | MUST | 0.5 | medium |
| Control center root + tiles + notifications subpage | MUST | 2.5 | high |
| Lock module integration (reuse) | MUST | 0.5 | medium |
| Expanded hover: media + week strip | SHOULD | 1.5 | high |
| Calendar month view, scroll, back to today | SHOULD | 1 | medium |
| Charging layer + animation + glow pulse | SHOULD | 1 | high |
| Notification glow pulse | SHOULD | 0.25 | low |
| Workspace fly animation on window move | SHOULD | 1 | medium |
| Native WiFi/BT pages | LATER | 3 | medium |
| Calendar events (khal + vdirsyncer) | LATER | 2 | medium |
| Laptop power button -> power menu | LATER | 0.5 | low |

## Demo data

- `test-notif.sh`-style script with `notify-send` covering normal, critical, with actions, replacing (same id) and burst (5 in a row).
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

## Deferred to v2

- Native WiFi/BT subpages (scan, connect, password) — high cost; v1 opens impala/bluetui.
- Calendar events — needs a data source (khal + vdirsyncer).
- Brightness right-click action — no clear use yet.
- Laptop power button binding — a separate diagnosis (logind `HandlePowerKey` / `libinput debug-events`).

## Demo priorities

1. Idle notch at rest + charging plug-in animation.
2. Workspace notch reacting to switching, opening and moving apps.
3. Hover expand with media + week.
4. Notification toast -> unread dot -> control center list.
5. Launcher apps + commands; power menu hold-confirm.

## Collaboration

- Mode: solo
- People: n/a
- Frozen contracts: n/a
- Work packages: n/a

## Plan-review resolutions

| # | Finding | Resolution | Decided by |
|---|---|---|---|

# Plan review: Quickshell notch shell (review 2)
Verdict: PASS WITH CHANGES
Summary: All 16 findings and the risks from review 1 are written into the plan, and ADR 0004 and the Makefile match them (single spacer zone, `NOTCH_SMOKE`). Two of those resolutions are incomplete. The cutover misses the root-owned system-sleep hook, which would let the laptop suspend without locking. The new mid-flow rules contradict the toast hover behaviour. The plan also never says whether the centre state machine runs once globally or once per monitor. With no deadline the scope fits; the plan's own MUST total is misadded by 1 day.

## Findings
| # | Category | Severity (blocker/major/minor) | Finding | Evidence | Suggested fix |
|---|---|---|---|---|---|
| 1 | Gap (R1-4 incomplete) | major | Lock-before-suspend breaks after cutover. The system-sleep hook runs `qs ipc call lock lock`, which only reaches the default config. Once only `qs -c notch` runs, every suspend (lid close, IdleManager's `suspend-then-hibernate`, the power-menu suspend) happens without locking. This is a security regression, and it fails silently because the hook ignores errors and waits only 3 s. The cutover item lists exec, env, IPC names, keybinds and rollback, but not this hook. Because the hook is root-owned, the cutover and the rollback both need sudo. | `/usr/lib/systemd/system-sleep/lock-before-sleep:29-32`; plan "Scope" row "Hyprland cutover"; plan "Plan-review resolutions" R1-4 | Add the hook to the cutover and the rollback: use `qs -c notch ipc call lock lock`, or have it try both configs. Keep the `lock` target with a `lock()` function. Note that the script needs root. Test it once with `systemctl suspend`. |
| 2 | Contradiction (R1-12) | major | The hover rules for toasts conflict. The toast mockup says hovering a toast expands the toast (actions, ✕). The mid-flow rule says "a critical toast does not block Expanded on hover". The plan does not say what a hover over a visible critical toast does, or where the critical toast goes while Expanded is showing. This is the MUST state machine that TDD has to pin down. | plan "Core model" mid-flow rules; plan "Main notch: notification toast" mockup + rules | Hovering a visible toast always expands the toast. After its first timeout, a critical toast collapses into a persistent `!` indicator (unread dot style) and Expanded becomes reachable. The critical stays in the control center list until dismissed. Add this as a reducer test case. |
| 3 | Gap | major | The plan never says whether the centre state machine is one global instance or one per monitor. Toasts show on every monitor, Expanded depends on hover per monitor, and launcher/power/polkit open only on the focused monitor. It is unclear whether a launcher open on monitor A suppresses toasts on B, and whether dismissing a critical toast on A clears it on B. The reducer's shape, and its tests, depend on this. | plan "Core model" (states + "keyboard states stay on the monitor where they opened"); "Data gaps" row Multi-monitor; ADR 0004 "Passive notches on every monitor" | Use one reducer instance per monitor, fed by global inputs (the notification queue, the lock state, `keyboardOwner: monitorName`). Suppression and the dismiss state are global; hover and Expanded are per monitor. Write this down in the core model. |
| 4 | Gap | minor | The workspaces notch does not say which workspaces it shows on each monitor (that monitor's workspaces or all of them), or how many slots it has. The old widget used a fixed `maxVisible`. | plan "Workspaces notch"; old `modules/bar/WorkspacesWidget.qml:49-50` | Add a rule: show the workspaces bound to that monitor (or all of them), with a slot-count token. |
| 5 | Contradiction | minor | The toast mockup shows `[ Mark read ]`, but the rules say the buttons are only the notification's own DBus actions. | plan "Main notch: notification toast" mockup vs rules line 143 | Either drop "Mark read" from the mockup, or name it as one local action always added next to the DBus actions. |
| 6 | Gap | minor | The old shell uses a different wallpaper and colour palette per monitor (`Wallpapers.currentFor(screenName)`, `Colours.paletteFor(screenName)`). The plan, and ADR 0005, describe a single matugen `primary`, so it is undefined which monitor's wallpaper drives the accents. | old `services/Wallpapers.qml:133`, `services/Colours.qml:210`; plan "Visual style"; ADR 0005 | Decide between one accent for every monitor (from the focused or primary monitor) and one per monitor, and record it in ADR 0005. |
| 7 | Gap | minor | Keybinds lose their targets. Super+N (notifications), Super+Alt+C (calendar) and Super+D (dashboard) have no matching v1 IPC. Expanded (media and calendar) can only be opened by hovering. | `~/.config/hypr/deadlock/keybinds.lua:202-206`; plan "Key events" IPC list | In the cutover item, map Super+N to `controlcenter` (notifications subpage) and Super+D to `controlcenter`. Either drop Super+Alt+C or add an IPC `expanded toggle`. |
| 8 | Gap | minor | Some old features are dropped without being listed as dropped: the weather tab (wttr.in) in the notifications panel, and the recording indicator at rest (the bar's RecorderWidget; in v1 recording state is only visible in the control center tile). | old `modules/notifications/WeatherTab.qml:57-58`, `modules/bar/RecorderWidget.qml`; plan "Deferred to v2" | List them explicitly as dropped or deferred. For recording, consider a small overlay on the idle notch (for example a red dot) while recording. |
| 9 | Gap | minor | It is unclear what "Opening the notification list marks notifications as seen" covers: the inline list on the control center root, which opens on hover, or only the subpage. If it is the root, any accidental corner hover clears the unread dot. | plan "Control center" rules | Mark notifications seen only when the subpage opens, or after the root has been visible for N ms. |
| 10 | Gap | minor | The plan does not say how DND treats critical urgency or the shell's own 10% battery toast. | plan "Notification toast" Suppression; "Main notch: idle" 10% rule | Critical urgency, and the battery toast, bypass DND. Put it in the queue tests. |
| 11 | Scope arithmetic | minor | The MUST rows add up to 32.5 days, but the plan says "~33.5". The one-time import of the old state and the hyprpaper fallback write have no estimate of their own. | plan "Scope" table; footer line 392 | Fix the total. Put the state import (0.25 d) under the service rewrites and the hook and keybind remap under cutover (+0.25 d). |
| 12 | Technical | minor | `NOTCH_SMOKE` skips the spacer zone, NotificationServer, PolkitAgent and IdleMonitors, but not the BG surface. Every `make check` (and every Stop hook run) maps full-screen background-layer surfaces, possibly with video decoding, over the live wallpaper for 10 s. It also runs the first-run state import against the real state directory. | ADR 0004 line 17; Makefile `smoke`; plan "Data gaps" row "Smoke test" | In smoke mode, also skip the BG surface media (or the whole surface) and the state import/writes. Update ADR 0004. |

Review-1 resolutions checked. The following are in place and correct: R1-1, R1-2 (old BG already uses `exclusiveZone: -1`, so it is compatible with R1-3), R1-3 (ADR 0004 line 16), R1-5, R1-6, R1-7, R1-8, R1-9, R1-10, R1-11, R1-13, R1-14 (still open, see "Unnamed risks"), R1-15 and R1-16. R1-4 is incomplete (finding 1). R1-12 introduced a new contradiction (finding 2). R1-risk "smoke" is partial (finding 12).

## Scope vs deadline
| Item | Est. dev-days | Cut (MUST/SHOULD/LATER) |
|---|---|---|
| Shell skeleton (surfaces, spacer zone, masks, ears, tokens, NOTCH_SMOKE incl. BG skip) | 3 | MUST |
| Service rewrites + Session adapter + Hypr wrapper + state import | 4.25 | MUST |
| Background surface + IdleInhibitor + hyprpaper fallback | 1 | MUST |
| Hyprland cutover (exec, env, IPC, keybind remap, sleep hook, rollback) | 0.75 | MUST |
| Main notch idle + low-battery layer + 10% toast | 1.5 | MUST |
| Main notch state machine (per-monitor instances, mid-flow, critical toast rule) | 2.5 | MUST |
| Workspaces notch | 3 | MUST |
| Volume/brightness OSDs | 1.5 | MUST |
| Toast + DND + unread | 2 | MUST |
| Launcher apps + commands + description pane | 2.5 | MUST |
| Command views: wallpaper, theme, keybinds | 2.5 | MUST |
| Power menu hold-confirm | 1 | MUST |
| Polkit state | 0.5 | MUST |
| Control center root + tiles + notifications subpage | 3 | MUST |
| System tray row | 1.5 | MUST |
| Lock integration | 1.5 | MUST |
| Expanded hover: media + week strip | 1.5 | MUST |
| Charging layer + animation + glow | 1 | SHOULD (1: demo #3) |
| Workspace fly animation | 1 | SHOULD (2: demo #2) |
| Calendar month view | 1 | SHOULD (3: demo #1 polish) |
| Command views: screensaver, security, webapp | 2 | SHOULD (4) |
| Low-battery breathing glow | 0.25 | SHOULD (5) |
| Notification glow pulse | 0.25 | SHOULD (6: demo #4) |
| OLED pixel shift | 0.25 | SHOULD (7) |
| Native WiFi/BT pages, khal events, power button | 5.5 | LATER |

Total MUST: 33.5 dev-days vs available: open-ended (solo, no deadline) -> fits

## Unnamed risks
- **The lock silently does nothing after suspend.** The sleep hook's IPC call fails without any error, so nobody notices until the laptop resumes unlocked. Likelihood: high if the hook is not updated. Mitigation: finding 1, plus a manual cutover checklist step: suspend and confirm the lock is up on resume.
- **Monitor hot-plug while a keyboard state is open.** The launcher, power menu or polkit prompt stays on the monitor where it opened. If that monitor is unplugged or the lid closes, `Variants` destroys the surface, and the `Exclusive` focus or the polkit flow is lost with no answer. Likelihood: medium. Mitigation: when a screen is removed, cancel polkit and close the keyboard states (add it as a reducer event).
- **The smoke instance receives real IPC.** If `qs ipc` resolves the symlinked `notch` config and the `qs -p shell/shell.qml` smoke run to the same instance identity, a lock or launcher IPC sent during the 10 s smoke window can go to the throwaway instance. Likelihood: low. Mitigation: in smoke mode, register no IpcHandlers, or verify with `qs list` during a smoke run.
- **The rfkill WiFi toggle needs root.** This is the plan's own open item. If it does, the WiFi tile in v1 only shows state. Likelihood: low–medium. Mitigation: check `rfkill block wlan` as the user early (in phase 1). The fallback is iwd's DBus `Powered` property. `Quickshell.Networking` exists on the host but probably targets NetworkManager.
- **Two video pipelines at once.** The video wallpaper on the BG surface plus the screensaver video inside LockSurface can both decode while locked, which costs battery on the laptop. Likelihood: medium. Mitigation: pause BG video while `Session.locked`.

## Questions for the user (max 5)
1. Should a critical notification (and the 10% battery toast) bypass DND and stay as a persistent indicator until dismissed? Why it matters: it decides finding 2 and finding 10 in the state machine. My recommendation: yes; it collapses to a `!` indicator after the first timeout.
2. Should toasts and suppression be global across monitors (dismissing on one dismisses on all, an open launcher mutes toasts everywhere)? Why it matters: it fixes the reducer shape (finding 3). My recommendation: one global queue and suppression, with hover and Expanded per monitor.
3. With per-monitor wallpapers, should notch accents follow each monitor's palette or a single shared one? Why it matters: it changes ADR 0005 and the Colours service. My recommendation: per monitor, since the old engine already supports it.
4. Are you OK dropping the weather tab, and do you want a recording indicator on the idle notch? Why it matters: both exist today and are absent from the plan. My recommendation: defer weather to v2, and add a small red recording dot to the idle notch as an overlay (MUST, about 0.25 d).
5. What should Super+D, Super+N and Super+Alt+C do after the cutover? Why it matters: these keybinds lose their targets. My recommendation: Super+D opens the control center, Super+N opens the notifications subpage, and Super+Alt+C toggles Expanded through a new IPC.

Technical recommendations (no user input needed): update the sleep hook in the cutover and the rollback (finding 1); hover over a toast always expands the toast (finding 2); skip the BG surface, the state import and IPC in smoke mode (finding 12, risks); cancel keyboard states when a screen is removed; pause the BG video while locked; mark notifications seen only when the subpage opens (finding 9); fix the MUST total (finding 11).

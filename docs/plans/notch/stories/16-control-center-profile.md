# Story 16: Hover control center with profile

## Story

16. As a user, I want a hover control center in the top-right with my profile (avatar, name, uptime) so that I have a home for system controls in the notch. Requires: #02

## Acceptance criteria

- [ ] Given the control center is collapsed (nothing drawn in the top-right corner), when I rest the pointer in the corner's small hot zone for about 200 ms, then the panel opens from the corner on that monitor showing an avatar with my initial, my user name and "up 3h 12m"-style uptime.
- [ ] Given the pointer only brushes the hot zone (less than about 200 ms), when it moves away, then nothing opens; given the panel is open, when the pointer leaves it, then it collapses back to nothing.
- [ ] Given the panel stays open for several minutes, when I look at it, then the uptime has advanced without reopening it, and the hot zone never blocks clicks outside its small corner area.

## Plan

- Service: a small OS-info singleton that exposes the user name and uptime from `/proc/uptime` on a slow refresh (reused from the old config, without the shell-outs it does not need).
- Logic: pure, tested uptime formatting ("3h 12m", "2d 4h", "0m") and the corner panel size; reuse the existing hover-delay rule if one fits.
- UI: the top-right surface stops being a placeholder; collapsed it is an invisible hot zone, open it is the corner shape with the profile header; mask follows the visible shape.
- Tokens: hot-zone size, panel sizes and the "up" label live in `config/` (hover delay already exists).

## Out of scope

- Tiles (WiFi, BT, DND, power profile, caffeine, Rec), power row, tray, notifications list and subpages (#17, #18, #19, #06, #07, #05).
- The `controlcenter` IPC target and keybinds (cutover, #14).
- Avatar images (`~/.face` etc.): the initial letter only, as in the old config.
- Subpage "stay open on brief leave" rule: there are no subpages yet.

## Suggestions (your call)

- The old `OsInfo` also reads os-release, kernel and hostname; nothing here shows them, so port only user and uptime.
- `cornerShape` in `logic/cornerLayout.mjs` sizes the TL body with ears on the top/left edges; the TR panel is its mirror and can likely reuse it unchanged.

## Size

normal
Risk: item 6 (hover open/close, hot zone and mask verified only manually)

## Log

- L1 request: /flow:story 04
- L2 split: 04 had more than 3 criteria and depended on #10 (power menu) and #12 (caffeine inhibitor); user approved split into #16 (panel + profile), #17 (WiFi/BT/DND tiles), #18 (power row), #19 (power profile + caffeine tiles). #05, #06, #07 now require #16.

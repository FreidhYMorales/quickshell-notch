# Story 19: Power profile and caffeine tiles

## Story

19. As a user, I want power profile and caffeine tiles in the control center so that I control performance and idle from the notch. Requires: #16, #12

## Acceptance criteria

- [ ] Given the control center is open, when I look at the tiles, then a caffeine tile shows off on every launch and lit after I turn it on, and while it is lit the session does not idle-sleep; clicking it again turns it off.
- [ ] Given the machine reports power profiles, when I left-click the profile tile, then it advances performance → balanced → power-saver → performance, the tile shows the active profile and is lit whenever it is not balanced, and a change made outside the shell shows up the next time the panel opens.
- [ ] Given the profile backend is missing, when the control center opens, then the profile tile is hidden and the rest of the row is unchanged.

## Plan

- Logic: extend the pure tile model with the two new ids (display order, on/off, hidden when the backend is missing) and the profile cycle; tests pin the order, the cycle and the missing-backend case.
- Services: a power-profile singleton reads the active profile and sets a new one, refreshing when the panel opens instead of holding a permanent watcher; caffeine already exists and only needs exposing.
- UI: two more tiles in the existing row, mapped to their glyph and action with the current left/right click rules; six 40px tiles fit the 280px row exactly.
- Tokens: one glyph per profile and the caffeine glyph live in `config/` with the rest of the UI text.
- Degrade: no backend means the tile is hidden and warns once, never a broken or dead button.

## Out of scope

- The segmented profile picker and its OSD from the old bar.
- Switching the profile automatically on AC/battery; the daemon may still do it, the shell only shows and follows it.
- Persisting caffeine across restarts; the inhibitor stays on the always-mapped wallpaper surface.
- The Recorder tile and the notifications subpage.
- The two-row tile grid of the plan mock; six tiles fit the current single row.

## Suggestions (your call)

- The old config's `BatteryProfile.qml` already knows this backend (`powerprofilesctl get|set`); port the commands, not its permanent `dbus-monitor` process, which the repo's AGENTS.md warns against ("avoid permanent forking polls").

## Size

normal
Risk: item 6 (the tile wiring and the real profile switch are verified only manually)

## Log

- L1 request: /flow-story 19
- L2 decision (user): the profile tile cycles performance → balanced → power-saver and is lit when not balanced, instead of three separate tiles or a segmented pill.
- L3 assumptions for approval: caffeine right-click does nothing (no detail to open); the profile is re-read when the panel opens rather than watched live; the caffeine tile already starts off because the service is session-only (story 12).

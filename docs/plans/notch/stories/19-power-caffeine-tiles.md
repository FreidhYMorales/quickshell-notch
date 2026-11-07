# Story 19: Power profile and caffeine tiles

## Story

19. As a user, I want power profile and caffeine tiles in the control center so that I control performance and idle from the notch. Requires: #16, #12

## Acceptance criteria

- [x] Given the control center is open, when I look at the tiles, then a caffeine tile shows off on every launch and lit after I turn it on, and while it is lit the session does not idle-sleep; clicking it again turns it off.
- [x] Given the machine reports power profiles, when I left-click the profile tile, then it advances performance → balanced → power-saver → performance, the tile shows the active profile and is lit whenever it is not balanced, and a change made outside the shell shows up the next time the panel opens.
- [x] Given the profile backend is missing, when the control center opens, then the profile tile is hidden and the rest of the row is unchanged.

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
Risk: item 6 (the real profile switch against the live daemon and the idle inhibitor are verified only manually; the tile wiring is pinned by the QML probe)

## Log

- L1 request: /flow-story 19
- L2 decision (user): the profile tile cycles performance → balanced → power-saver and is lit when not balanced, instead of three separate tiles or a segmented pill.
- L3 assumptions for approval: caffeine right-click does nothing (no detail to open); the profile is re-read when the panel opens rather than watched live; the caffeine tile already starts off because the service is session-only (story 12).
- L4 build: 5d547f3 test → 9c6b12a feat (tile order); cbaca81 test → e4195ac feat (profile lit only when not balanced); 5237d98 test → e823c18 feat (cycleProfile); b179cec feat (PowerProfile service, glyphs and tile wiring); e570044 fix (user-picked glyphs: speedometer for performance, yin-yang for balanced, leaf stays for power-saver).
- L5 correction (verifier): first FAIL (no pin for the hidden profile tile, caffeine flag untested) → 64a7bf5 adds both unit pins and the controlcenter-tiles probe; second FAIL (the probe set the service directly, so deleting the tile's `onToggled` stayed green) → user chose to extend the probe → 1732950 clicks the caffeine tile and asserts the service flips, then sets `PowerProfile.current` to `power-saver` and asserts the leaf glyph renders lit. Mutation check: with `onToggled` removed the probe fails with "cc tiles: click did not toggle caffeine".
- L6 evidence: `make check` → 538 unit tests pass, all QML probes pass, "smoke: config loaded". Manual criteria confirmed by the user: the caffeine tile lights and the idle inhibitor holds; the profile tile cycles and stays in sync with the old bar in both directions. Verifier refs and HEAD unchanged after both runs.
- Risk: item 6 (the real profile switch against the live daemon and the idle inhibitor are verified only manually; the tile wiring is pinned by the QML probe)

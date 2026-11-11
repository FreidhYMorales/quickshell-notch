# 0006. In-memory capture for the lock backdrop

- Status: accepted
- Date: 2026-11-10

## Context

When the session locks, the compositor covers every screen with a secure
surface immediately. Showing the wallpaper there makes the surroundings of the
notch flash a different image before the reveal animation starts. The previous
implementation ran `grim` per monitor, wrote PNGs to a runtime directory and
loaded them as files. That added process startup, disk I/O and cleanup, and it
still captured before the lock.

## Decision

- Capture each screen with `ScreencopyView` (`live: false`) inside a hidden 1x1
  layer surface, one `LockFrame` per screen (`shell/lock/LockFrame.qml`).
- Ask the lock only when every screen has a frame, or when
  `Timings.lockCaptureTimeout` (500 ms) expires, whichever comes first
  (`LockFrameGate`). Failure or an expired deadline still locks, with the
  wallpaper as fallback.
- Attach frames to the secure surface as soon as the surface learns its screen,
  before the compositor maps it; do not wait for `secure` to attach a frame that
  was already captured. Do not attach frames that arrive later, because a
  capture completed after the compositor took over was observed black.
- Release every frame when the lock ends. Nothing is written to disk.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| `grim` subprocess per monitor | Simple, already worked | Process + disk latency, files to clean up | Slower; leaves screenshots on disk |
| Capture concurrently with the lock request | No pre-lock wait | Verified black screen in practice | Loses the desktop backdrop |
| Fixed delay before locking | Predictable code | Unbounded security cost, still timing-dependent | Worse than waiting for the frame |
| No capture, wallpaper only | Fastest lock | Visible image change around the notch | Design regression |

## Consequences

- Positive: no files, no subprocess; measured 73 ms to frame and 145 ms to a
  secure lock in an isolated probe; the frame survived the secure transition
  and was released cleanly after unlock. In the live session the frozen desktop
  is the first painted frame, with no wallpaper flash.
- Negative: a bounded interval remains between capture and the compositor
  confirming `secure` (~70-150 ms in the probe, at most 500 ms). A screen with
  no frame shows the wallpaper.
- Follow-ups: multi-monitor visual validation; a capture that fails on one
  monitor currently keeps the wallpaper there, which is deliberate.

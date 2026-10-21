# 0004. Layer surfaces, input masks and focus

- Status: accepted
- Date: 2026-10-21

## Context

Notches sit on the top edge of every monitor. The old paused notch attempt swallowed clicks across the whole top strip, and resizing a layer surface every animation frame flickers. Zero-size surfaces receive no hover.

## Decision

- One set of surfaces per monitor: `Variants` -> `Scope` -> `PanelWindow` (wrapper roots are `Item`, not `Variants`).
- Fixed-size surfaces; animate inside them. Anchor left+right for a true (0,0) origin.
- Every surface MUST set `mask: Region { item: ... }`.
- Exclusive zone = idle notch height, reserved by default; expanded states overlay temporarily; `reserveSpace` toggle in config.
- Keyboard focus: `None` for passive notches/OSDs; `Exclusive` only while launcher, power menu or polkit is open.
- Passive notches on every monitor; keyboard states only on the focused monitor.
- Hover uses a hitbox strip and debounced close; ~200ms open delay on corners.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| One full-width surface per monitor | Fewer windows | Needs perfect masks; any gap swallows clicks | Old attempt failed this way |
| Resize the surface to animate | Tight bounds | Flicker | Observed artefacts |
| No exclusive zone (pure overlay) | Max screen space | Windows sit under the idle notch | Reserve by default, toggle available |

## Consequences

- Positive: predictable input, no flicker, multi-monitor by construction.
- Negative: surfaces sized for the largest state; masks must track the visible shape.
- Follow-ups: shared `NotchZone`/hitbox component; manual check of click-through on every new surface.

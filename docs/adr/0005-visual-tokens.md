# 0005. Visual tokens

- Status: accepted
- Date: 2026-10-21

## Context

The notch must look like part of the bezel on an OLED laptop panel. The old config used permanent glow/shadows via MultiEffect, which produced artefacts and risks burn-in. Colours come from matugen (wallpaper-driven).

## Decision

- Notch background: pure `#000`, opaque.
- Inner cards: black mixed 6-10% with matugen `primary`.
- Accents: matugen DARK-scheme `primary`, always (independent of light/dark mode).
- Text: dark-scheme `on_surface` + a muted variant.
- No permanent glow/shadow; glow only as brief event feedback (plug-in, notification arrival).
- Concave ears (EarCurve.js) wherever a notch meets a screen edge.
- Font: "IosevkaTerm Nerd Font", defined once in `shell/config/`. All timings, colours and strings are tokens there.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Surface colour from matugen as background | Themed | Breaks the bezel illusion | Black is the point |
| Follow light/dark scheme for accents | Consistent with apps | Light accents on black look washed out | Dark scheme reads well on black |

## Consequences

- Positive: consistent look; single place to change font, colours, timings.
- Negative: wallpapers with dull primaries give dull accents.
- Follow-ups: `Colours` singleton reads matugen output (reuse ColoursEngine).

# Story 34: Quick Wallpaper fullscreen selector

## Story

34. As a user, I want a keyboard-triggered fullscreen wallpaper picker that morphs out of the centre notch so that I can preview and select wallpapers quickly without losing the clock and date. Requires: #27

## Visual specification

- Inspiration: HyprQuickPaper's Coverflow Clear presentation, adapted to the notch's own design system. This is an original implementation, not a code transplant.
- The centre notch visually expands to fill the current monitor, and contracts back to its original shape on exit. The transition must read as one continuous surface.
- The selected wallpaper fills the fullscreen background preview. Keep the clock and date readable in the upper/central clear area, with local contrast treatment rather than a heavy full-screen overlay.
- The carousel is anchored to the bottom of the screen. Its entire allocated area, including cards, labels and controls, MUST NOT exceed one third of the available screen height; use responsive dimensions for varying monitor sizes.
- Carousel cards use portrait (vertical rectangular) aspect ratios. The central card is upright, larger and emphasized; adjacent cards are smaller and tilted slightly outward. More distant cards fade or shrink gradually.
- Navigation animates translation, scale and tilt. Background preview cross-fades when the selected item changes, including image/video candidates, without changing the committed wallpaper.
- Motion, typography, colors and labels MUST use the shared shell/config tokens; animations SHOULD remain responsive on integrated GPUs.

## Acceptance criteria

- [ ] Given the configured Hyprland keybind or IPC command, when triggered, then Quick Wallpaper opens directly without navigating through the launcher; triggering it does not automatically cycle wallpapers.
- [ ] Given the selector opens, when its opening animation completes, then the fullscreen preview, clock, date and bottom-anchored portrait carousel are visible and the carousel uses at most 1/3 of screen height.
- [ ] Given I press Left/Right (optionally h/l), when the selection changes, then the centre card becomes upright, side cards tilt and the fullscreen background preview updates immediately with a smooth transition.
- [ ] Given I press Enter, when I confirm, then the chosen wallpaper is committed through the shared service, the configured theme/palette refresh is invoked only at commit, and the surface contracts into the centre notch.
- [ ] Given I press Escape, when I cancel, then the prior committed wallpaper is restored visually and no wallpaper or palette state is written.
- [ ] Given I click a side card, when it is selected, then it moves to centre; clicking the already selected card MAY confirm, subject to manual UX verification.
- [ ] Given multiple monitors, when I invoke the selector, then it opens on the intended monitor and uses the same monitor-target rules as story 27.
- [ ] Given the selector is open, when another notch view or lock/session state changes, then focus and layer handling prevent conflicting overlays and the selector closes safely if necessary.
- [ ] Given an unavailable file, video decoder failure, missing thumbnail or empty directory, when displayed, then the picker degrades gracefully without losing keyboard escape.
- [ ] Given I close the selector, when the exit animation finishes, then the notch's previous content, focus behavior and click-through outside its mask are restored.

## Architecture and phases

1. Specify/test pure selection state, wraparound, preview/commit/cancel, screen targeting and transition states in shell/logic.
2. Reuse Wallpapers catalog, preview and persistence API from story 27; avoid a second wallpaper backend.
3. Add a dedicated fullscreen picker surface coordinated with the centre notch. Animate internal geometry and its interactive mask; avoid repeated PanelWindow resize and avoid blocking the desktop outside the active surface.
4. Implement the portrait coverflow with config-driven dimensions and motion, plus clock/date overlay and cross-fading fullscreen preview.
5. Wire an IPC entry point for a Hyprland keybind, document a sample bind without silently changing the user's live Hyprland config.
6. Validate manually on Wayland across monitor sizes, video/image content, cancel/commit, focus, masks, lock transitions and animations; run make check locally.

## Out of scope

- Changing wallpaper directly on every keybind press without opening the picker.
- Theme or keybind command view implementations (#28, #29).
- Replacing the current WallpaperSurface renderer or introducing a separate wallpaper daemon.

## Risks and rollback

Risk: high (fullscreen layer-shell surface, focus, input mask, animation and multi-monitor video preview). Implement in isolated increments; keep a kill/disable path for the picker IPC while preserving existing notch behavior and saved wallpapers. No production activation until manual Wayland verification.

## Log

- User selected a fullscreen experience inspired by HyprQuickPaper Coverflow Clear.
- Clock and date remain visible during wallpaper selection.
- Portrait cards: central upright, lateral cards slightly inclined.
- The carousel stays at the very bottom and its allocated height is at most one third of the screen.
- Moving selection changes the fullscreen visual preview immediately; commit only on confirmation, cancel restores the previous background.
- Keybind opens the selector only, never cycles wallpapers directly.

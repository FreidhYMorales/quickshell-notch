# Story 27: Wallpaper command view

## Story

27. As a user, I want a wallpaper configuration view inside the launcher so that I can browse, preview and apply wallpapers without leaving the notch. Requires: #26

## Acceptance criteria

- [x] Given the launcher is in command mode, when I activate Wallpaper, then a dedicated wallpaper view opens; Theme and Keybinds remain unavailable until their own stories.
- [x] Given a configured wallpaper directory, when the view opens, then supported image and video files are catalogued with thumbnails, current selection and a usable empty/error state. The default directory and optional override follow the existing wallpaper configuration conventions.
- [x] Given wallpapers are available, when I navigate the horizontal carousel by keyboard or pointer, then the highlighted wallpaper is previewed without persisting the choice.
- [x] Given I confirm, when I apply the selection, then the intended monitor or global wallpaper is saved in the notch's own state and its background updates; any configured palette refresh occurs only on commit.
- [x] Given I cancel or close, when I leave without confirming, then the previously committed wallpaper remains effective.
- [x] Given multiple monitors, when I select a target, then the change respects the existing default/per-monitor fallback model without unexpectedly replacing other monitor overrides.
- [x] Given an invalid path, unreadable file, unsupported video or missing thumbnail tool, when it is encountered, then the view degrades gracefully without crashing the shell.
- [x] Given app search or another launcher command, when I return from wallpaper mode, then existing launcher navigation and state remain intact.

## Design and plan

1. Add pure wallpaper catalog, selection, preview/commit and monitor-target decisions in shell/logic with strict TDD.
2. Extend the Wallpapers singleton as the shared state/data boundary: discover entries, track temporary preview separately from committed state, save on explicit confirmation, and preserve one-time legacy state import.
3. Add shared thumbnail/card and navigation components using shell/config tokens; support image and video entries with a graceful video thumbnail fallback.
4. Integrate a compact horizontal carousel and monitor/configuration controls into the existing launcher command view.
5. Verify regression of app mode, other command views, per-monitor persistence, cancellation, missing files, images and videos; run make check locally and manually inspect qs -c notch.

## Out of scope

- Fullscreen keyboard-triggered Quick Wallpaper selector (story 34).
- Reimplementing the theme command view (#28) or keybinds command view (#29).
- Introducing a separate wallpaper daemon, replacing the existing renderer, or changing unrelated control-center tiles.

## Implementation notes

- Preserve the architecture: services provide data, pure JS decides, QML renders.
- Existing Wallpapers.qml currently reads/imports state but does not provide a wallpaper catalog or a commit API.
- WallpaperSurface.qml renders images and videos per monitor; extend preview semantics without replacing the background renderer.
- Do not write to the legacy state directory; use the notch's own state files.
- Prefer reusable components and APIs that story 34 can consume.
- Keep changes reviewable in small TDD steps; do not claim runtime verification without running it on Wayland.

## Risk and rollback

Risk: medium (persistent wallpaper state, per-monitor behavior and video playback). Keep all changes on a feature branch, preserve existing state format, and roll back the launcher entry/preview binding independently if necessary.

## Verification

- Maintainer confirmed make check passed and runtime was clean on Arch/Hyprland.
- Confirmed launcher wallpaper selection, circular navigation, rounded thumbnails, Enter apply/close, Escape cancel, and wallpaper persistence.
- Implementation is in PR #26; not merged into main. Story #34 remains separate.

## Log

- User chose a horizontal carousel for the launcher command view, based on their older Quickshell configuration, but with refinements.
- Quick Wallpaper was separated as its own experience and is specified in story 34.

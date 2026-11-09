# Backlog: notch

## Context

- What: Quickshell notch shell replacing the old bar on Arch + Hyprland, for daily use by the maintainer. Plan: docs/plans/notch/plan.md (phases 1-3 done, archived under openspec/changes/archive/).
- Stack: QML + Quickshell 0.3 (Qt 6.12), pure JS ES modules in shell/logic, matugen.
- Expensive decisions: none
- Test command: make check
- Single test: node --test tests/<name>.test.mjs

## Backlog

01. [x] 538e39f As a user, I want incoming notifications to show as a compact toast in the centre notch that expands on hover with its actions so that I see them without leaving my work.
02. [x] eb640ed As a user, I want do-not-disturb and an unread dot (blinking while the launcher is open) so that notifications never interrupt me but I still know they arrived. Requires: #01
03. [x] 638524d As a user, I want critical notifications, including the 10% battery warning even at shell start, to bypass do-not-disturb and stay as a ! until I dismiss them so that I never miss urgent ones. Requires: #01
04. [-] split → #16, #17, #18, #19
05. [-] split → #20, #21
06. [-] split → #22, #23
07. [x] dfaac92 As a user, I want to start and stop screen recording from the control center and see the red dot on the notch while recording so that I know I am recording. Requires: #16
08. [x] 6584f09 As a user, I want an app launcher that morphs out of the centre notch so that I can find and open apps from the keyboard.
09. [-] split → #26, #27, #28, #29
10. [x] 44a7656 As a user, I want a power menu (Ctrl+Alt+Del, hold to confirm) so that I can lock, suspend, log out, reboot and shut down safely.
11. [x] c2461fb As a user, I want polkit password prompts in the centre notch so that apps can ask for admin rights.
12. [x] 00e135c As a user, I want the notch shell to render my wallpaper (including video) and keep caffeine working so that it can replace the old shell.
13. [-] split → #30, #31, #32
14. [x] faf97ed As a user, I want Hyprland to start the notch shell with my keybinds remapped and a rollback so that it becomes my daily shell. Requires: #08, #10, #12, #13
15. [ ] As a user, I want polished animations (charging glow, low-battery pulse, workspace fly, expanded cross-fade, OLED pixel shift) so that the notch feels alive.
16. [x] f3fb555 As a user, I want a hover control center in the top-right with my profile (avatar, name, uptime) so that I have a home for system controls in the notch. Requires: #02
17. [x] c683110 As a user, I want toggle tiles for WiFi, Bluetooth and DND in the control center so that I switch them without leaving my work. Requires: #16
18. [x] 71f319f As a user, I want a power row in the control center (lock, suspend, logout, reboot, shutdown) so that I reach session actions from the notch. Requires: #16, #10
19. [x] e570044 As a user, I want power profile and caffeine tiles in the control center so that I control performance and idle from the notch. Requires: #16, #12
20. [x] 553a526 As a user, I want my latest notifications in the control center (up to 3, count, clear all) so that I can review what I missed. Requires: #01, #16
21. [x] 876dedd As a user, I want a notifications subpage in the control center (full list, per-item dismiss, DND, back) that clears the unread dot so that I can manage my whole history. Requires: #20, #17
22. [x] ad0a64e As a user, I want the tray icons in the workspaces notch to open on hover so that I can see and restore apps minimised to the tray.
23. [x] 8fe1e16 As a user, I want a tray icon's own menu on right click so that I can use its actions without restoring its window. Requires: #22
24. [ ] LAST As a user, I want tray icons with failures hidden by Quickshell to show a recognizable fallback instead of its placeholder so that I can identify those apps. Requires: #22
25. [ ] BLOCKED (Quickshell submenu loading) As a user, I want to navigate a tray app's submenus inside the notch and return to the parent menu so that I can use nested actions without floating windows. Requires: #23
26. [x] 64af4aa As a user, I want to browse and search launcher commands with a description pane so that I can understand the available setup actions. Requires: #08
27. [x] IMPLEMENTED AND LOCALLY VERIFIED (wallpaper command view present in main; earlier PR #26 status not independently verified) As a user, I want the wallpaper command view so that I can change my wallpaper from the launcher. Requires: #26
28. [x] 116b9a6 As a user, I want the theme command view so that I can change my theme from the launcher. Requires: #26
29. [ ] As a user, I want the keybinds command view so that I can access my keybinds from the launcher. Requires: #26
30. [x] 5b49c55 As a user, I want to lock my session from the notch shell and unlock it with my password so that my session stays protected.
31. [x] 11498fb As a user, I want an idle chain (screensaver and lock together, then suspend) with my old timeouts so that an unattended session locks and sleeps on its own. Requires: #30, #12
32. [x] 6e7946a As a user, I want every suspend to lock the notch session first so that my session is already protected when it resumes. Requires: #30
33. [ ] As a user, I want a lock screen redesigned in the notch style so that my lock matches my shell and no longer depends on the SDDM theme. Requires: #30
34. [x] 1c7a44e (PR #27, squash-merged into main; CI green as reported by maintainer) As a user, I want a fullscreen Quick Wallpaper picker expanding from the centre notch, with a bottom portrait coverflow (at most one third of screen height), clock/date and live preview, opened by keybind. Requires: #27
35. [ ] As a user, I want the screensaver command view in the launcher so that I can tune the screensaver, lock and suspend timeouts from the notch. Requires: #26, #31
36. [ ] As a user, I want the security command view in the launcher so that I can enable fingerprint unlock and manage my registered fingers. Requires: #26, #30
37. [ ] As a user, I want the webapp command view in the launcher so that I can install a website as a desktop web app. Requires: #26
38. [ ] As a user, I want a month view in the expanded notch calendar with week/month scrolling and a jump back to today so that I can look beyond the current week. Requires: —
39. [ ] As a user, I want a glow pulse when a notification arrives so that I notice it without being interrupted. Requires: #01
40. [ ] As a user, I want a Light/Dark switch in the theme view that re-themes my apps without changing the notch so that I get the old view's light mode while the notch keeps its black look. Requires: #28

## Wallpaper work status

- #27: wallpaper command view implemented and locally verified; functionality is present in `main`. The historical status of PR #26 has not been independently verified here.
- #34: fullscreen Quick Wallpaper picker implemented and merged into `main` via PR #27 (squash commit `1c7a44e`). The maintainer confirmed that both CI jobs passed and that local image/video preview, transitions and persistence worked.
- #34 validation limitations: multi-monitor behavior was not tested because a second monitor was unavailable. Other unconfirmed manual edge cases (Escape/persistence, lock/session interactions, focus and click-through restoration, missing files and decoder failures) are not marked as passed; issues discovered later can be handled in follow-up stories.
- The unreliable nested Hyprland compositor CI probe was removed. Functional validation was performed on the maintainer's own environment, not through that hosted compositor probe.
- Remaining open stories: #15, #24 (LAST), #25 (BLOCKED by Quickshell submenu loading), #29, #33, #35, #36, #37, #38, #39 and #40.
- #35-#39 cover plan SHOULD items that had no backlog entry: the screensaver, security and webapp command views (plan line 335), the calendar month view (line 337) and the notification glow pulse (line 338).

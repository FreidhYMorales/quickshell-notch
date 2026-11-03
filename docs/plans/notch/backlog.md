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
08. [~] As a user, I want an app launcher that morphs out of the centre notch so that I can find and open apps from the keyboard.
09. [ ] As a user, I want launcher commands with a description pane (wallpaper, theme, keybinds) so that I change my setup without leaving the keyboard. Requires: #08
10. [x] 44a7656 As a user, I want a power menu (Ctrl+Alt+Del, hold to confirm) so that I can lock, suspend, log out, reboot and shut down safely.
11. [ ] As a user, I want polkit password prompts in the centre notch so that apps can ask for admin rights.
12. [ ] As a user, I want the notch shell to render my wallpaper (including video) and keep caffeine working so that it can replace the old shell.
13. [ ] As a user, I want the lock screen, including locking before suspend, to work from the notch shell so that my session stays protected.
14. [ ] As a user, I want Hyprland to start the notch shell with my keybinds remapped and a rollback so that it becomes my daily shell. Requires: #08, #10, #12, #13
15. [ ] As a user, I want polished animations (charging glow, low-battery pulse, workspace fly, expanded cross-fade, OLED pixel shift) so that the notch feels alive.
16. [x] f3fb555 As a user, I want a hover control center in the top-right with my profile (avatar, name, uptime) so that I have a home for system controls in the notch. Requires: #02
17. [x] c683110 As a user, I want toggle tiles for WiFi, Bluetooth and DND in the control center so that I switch them without leaving my work. Requires: #16
18. [x] 71f319f As a user, I want a power row in the control center (lock, suspend, logout, reboot, shutdown) so that I reach session actions from the notch. Requires: #16, #10
19. [ ] As a user, I want power profile and caffeine tiles in the control center so that I control performance and idle from the notch. Requires: #16, #12
20. [x] 553a526 As a user, I want my latest notifications in the control center (up to 3, count, clear all) so that I can review what I missed. Requires: #01, #16
21. [x] 876dedd As a user, I want a notifications subpage in the control center (full list, per-item dismiss, DND, back) that clears the unread dot so that I can manage my whole history. Requires: #20, #17
22. [x] ad0a64e As a user, I want the tray icons in the workspaces notch to open on hover so that I can see and restore apps minimised to the tray.
23. [x] 8fe1e16 As a user, I want a tray icon's own menu on right click so that I can use its actions without restoring its window. Requires: #22
24. [ ] As a user, I want tray icons with failures hidden by Quickshell to show a recognizable fallback instead of its placeholder so that I can identify those apps. Requires: #22
25. [ ] BLOCKED (Quickshell submenu loading) As a user, I want to navigate a tray app's submenus inside the notch and return to the parent menu so that I can use nested actions without floating windows. Requires: #23

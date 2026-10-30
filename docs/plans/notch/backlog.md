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
04. [ ] As a user, I want a hover control center in the top-right with my profile, uptime, power row and toggle tiles (WiFi, Bluetooth, DND, power profile, caffeine) so that I control the system from the notch. Requires: #02
05. [ ] As a user, I want my notification history in the control center (latest 3 inline, full subpage, clear all) so that I can review what I missed. Requires: #01, #04
06. [ ] As a user, I want a tray row in the control center so that I can restore apps minimised to the tray. Requires: #04
07. [ ] As a user, I want to start and stop screen recording from the control center and see the red dot on the notch while recording so that I know I am recording. Requires: #04
08. [ ] As a user, I want an app launcher that morphs out of the centre notch so that I can find and open apps from the keyboard.
09. [ ] As a user, I want launcher commands with a description pane (wallpaper, theme, keybinds) so that I change my setup without leaving the keyboard. Requires: #08
10. [ ] As a user, I want a power menu (Ctrl+Alt+Del, hold to confirm) so that I can lock, suspend, log out, reboot and shut down safely.
11. [ ] As a user, I want polkit password prompts in the centre notch so that apps can ask for admin rights.
12. [ ] As a user, I want the notch shell to render my wallpaper (including video) and keep caffeine working so that it can replace the old shell.
13. [ ] As a user, I want the lock screen, including locking before suspend, to work from the notch shell so that my session stays protected.
14. [ ] As a user, I want Hyprland to start the notch shell with my keybinds remapped and a rollback so that it becomes my daily shell. Requires: #08, #10, #12, #13
15. [ ] As a user, I want polished animations (charging glow, low-battery pulse, workspace fly, expanded cross-fade, OLED pixel shift) so that the notch feels alive.

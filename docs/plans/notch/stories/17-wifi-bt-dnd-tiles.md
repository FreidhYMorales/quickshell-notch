# Story 17: WiFi, Bluetooth and DND tiles

## Story

17. As a user, I want toggle tiles for WiFi, Bluetooth and DND in the control center so that I switch them without leaving my work. Requires: #16

## Acceptance criteria

- [ ] Given the control center is open, when I look at the tiles, then WiFi, Bluetooth and DND show lit when on and dim when off, matching the system, and they follow changes made elsewhere (`rfkill`, `bluetoothctl`, the `notifs` IPC) without reopening; a tile whose backend is missing is hidden.
- [ ] Given a tile, when I left-click it, then the WiFi radio, the Bluetooth adapter power or DND toggles and the tile shows the new state.
- [ ] Given the WiFi or Bluetooth tile, when I right-click it, then impala or bluetui opens in a kitty window; right-click on DND does nothing yet.

## Plan

- Services: WiFi radio state and toggle through `rfkill` (event-driven, no polling; root-less because `/dev/rfkill` grants the user rw via uaccess, checked with `getfacl`); Bluetooth from the default `Quickshell.Bluetooth` adapter; DND from `Notifs`.
- Logic: pure, tested parsing of the rfkill state and the tile model (which tiles show, on/off).
- UI: a tile row under the profile header; left click toggles, right click launches the TUI (detached, fixed command).
- Tokens: tile sizes, glyphs, labels and the two terminal commands live in `config/`; the panel grows to fit.

## Out of scope

- Power profile, caffeine and Rec tiles (#19, #07); power row (#18).
- DND right click and the notifications subpage (#05).
- Native WiFi/Bluetooth pages, scan or connect (v2).
- Hard-blocked radios get no special UI beyond showing off.

## Suggestions (your call)

- The old config already launches `kitty --class qs-wifi -e impala` and `kitty --class qs-bluetooth -e bluetui` (`modules/bar/WifiWidget.qml`, `BluetoothWidget.qml`); reuse the same classes so existing window rules still apply.

## Size

normal
Risk: item 6 (toggles act on real radios and the TUI launch are verified only manually)

## Log

- L1 request: /flow:story 17

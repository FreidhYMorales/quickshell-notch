# Development setup: Quickshell notch shell

Anyone must be able to go from a fresh clone to a green `make check` with this file alone, on any supported dev OS.

## Supported dev environments

| OS | Status | Notes |
|---|---|---|
| Arch Linux + Hyprland | supported | Maintainer's machine; the only target |
| Other distros / compositors / macOS / Windows | unsupported | Quickshell + Hyprland are required to run the shell |

## Toolchain versions

Pinned in: n/a. Arch is rolling; versions follow the system packages. Verified on: Quickshell 0.3.2, Qt 6.12, Node 26, deno 2.9, matugen 4.2.

Line endings: `.gitattributes` forces LF (`* text=auto eol=lf`). A clone made before it landed: `git add --renormalize . && git checkout -- .`.

| Tool | Version | Why it is needed |
|---|---|---|
| quickshell-git | 0.3.x | Runtime (`qs`), Quickshell QML types for qmllint |
| qt6-declarative | 6.12 | `qmlformat`, `qmllint` in `/usr/lib/qt6/bin` |
| nodejs | 26.x | `node --test` for `shell/logic` |
| deno | 2.x | `deno fmt`, `deno lint` for `.mjs` |
| matugen | 4.x | Colour scheme generation |
| ttf-iosevkaterm-nerd | any | UI font (IosevkaTerm Nerd Font) |
| make | any | `make check` quality gate |
| python-dbus, python-gobject | system | Isolated D-Bus tray fixture for QML tests |
| cava | 1.0 | Audio visualizer in the idle media layer (optional at runtime: without it only the visualizer hides) |
| brightnessctl | any | Backlight read and set for the brightness OSD (optional at runtime: without it or a backlight device only that OSD hides) |
| udevadm (systemd) | any | Backlight change watcher (`udevadm monitor --subsystem-match=backlight`); ships with systemd |
| pipewire | any | Volume and mute for the volume OSD through `Quickshell.Services.Pipewire` (no `wpctl` needed by the shell) |

## Install prerequisites

### Arch Linux

```bash
sudo pacman -S --needed qt6-declarative nodejs deno matugen ttf-iosevkaterm-nerd make cava brightnessctl python-dbus python-gobject
yay -S quickshell-git
```

Use `/usr/lib/qt6/bin/qmlformat` and `/usr/lib/qt6/bin/qmllint`: `/usr/bin/qmllint` and `/usr/bin/qmlformat` belong to Qt 5 (`qt5-declarative`) on this host. The Makefile uses the Qt 6 paths.

### Debian / Ubuntu

n/a (unsupported)

### macOS

n/a (unsupported)

### Windows

n/a (unsupported)

## First run

```bash
git clone <repo-url> quickshell-notch
cd quickshell-notch
# no .env: this project has no secrets
make check                                   # must pass before you change anything
qs -p shell/shell.qml                        # runs next to the old bar; Ctrl+C to stop
# The live config is the dotfiles submodule at ~/.config/quickshell/notch;
# see "Cutover and rollback" before touching it.
```

## Cutover and rollback

The notch becomes the daily shell through the dotfiles repo, never by editing
this checkout into `~/.config/quickshell`:

- The dotfiles quickshell package holds the old config at
  `.config/quickshell/default/` and this repo as a submodule at
  `.config/quickshell/notch/`. Quickshell ignores subdirectories when
  `shell.qml` sits at the top of `~/.config/quickshell`, which is why the old
  config moved into `default/`; bare `qs` still runs it by name.
- `./deploy.sh quickshell` stows the package and initialises the submodule, so
  a fresh clone plus deploy gives `qs -c notch` with no manual link.

```bash
scripts/notch-cutover.sh cutover    # stop both shells, remap the Hyprland
                                    # files, start the notch
scripts/notch-cutover.sh rollback   # restore the backups, start the old bar
```

The script keeps the originals in `~/.local/state/quickshell-notch/cutover/`
and never overwrites that first backup. Both shells are stopped first: they
would otherwise fight over the notification D-Bus name, the polkit agent and
idle locking. Lock-before-suspend needs no root hook: the notch shell locks
itself on logind's `PrepareForSleep` (see below).

## Daily commands

| Task | Command |
|---|---|
| Run the app from the checkout | `qs -p shell/shell.qml` |
| Run the live shell (after cutover) | `qs -c notch` |
| Cut over / roll back | `scripts/notch-cutover.sh cutover` / `rollback` |
| See every slot | set `showPlaceholders: true` in `shell/config/Flags.qml` (do not commit) |
| Tests | `make test` (`node --test tests/`) |
| QML runtime tests | `make qml-test` (isolated tray fixture and `qs`) |
| Lint | `make lint` |
| Smoke | `make smoke` |
| Format | `make fmt` |
| Full quality gate | `make check` |

## Lock before suspend

The notch shell locks itself before every suspend: it holds a logind sleep
inhibitor in delay mode and locks on `PrepareForSleep`. No root hook is
needed. A `system-sleep` hook cannot do it: systemd >= 256 freezes
`user.slice` before running those hooks, so the shell can no longer answer.
If you installed the earlier hook from this repo, remove it:

```bash
sudo rm -r /usr/local/lib/quickshell-notch /usr/lib/systemd/system-sleep/lock-before-sleep
```

## Troubleshooting

| Symptom | OS | Fix |
|---|---|---|
| qmllint reports Qt 5 errors / unknown Quickshell types | Arch | Use `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml`, not `/usr/bin/qmllint` |
| New component "is not a type" | Arch | Add it to the folder's `qmldir` |
| Clicks across the top strip are swallowed | Arch | The surface lacks `mask: Region { item: ... }` |
| Dispatch has no effect | Arch | Use the `hl.dsp.*` Lua bridge, not `Hyprland.dispatch` |
| Brightness OSD never appears | Arch | Needs a device in `/sys/class/backlight` and `brightnessctl` on PATH; the log shows `Brightness: no usable backlight` |
| `qs -c notch` says config not found | Arch | Run the dotfiles deploy: it initialises the notch submodule and stows it as `~/.config/quickshell/notch` |

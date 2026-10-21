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

## Install prerequisites

### Arch Linux

```bash
sudo pacman -S --needed qt6-declarative nodejs deno matugen ttf-iosevkaterm-nerd make
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
mkdir -p ~/.config/quickshell
ln -s "$PWD/shell" ~/.config/quickshell/notch
qs -c notch                                  # the old bar (~/.config/quickshell) stays as fallback: `qs`
```

## Daily commands

| Task | Command |
|---|---|
| Run the app | `qs -c notch` (stop the old bar first) |
| Run from the repo without the symlink | `qs -p shell/shell.qml` |
| Tests | `make test` (`node --test tests/`) |
| Lint | `make lint` |
| Smoke | `make smoke` |
| Format | `make fmt` |
| Full quality gate | `make check` |

## Troubleshooting

| Symptom | OS | Fix |
|---|---|---|
| qmllint reports Qt 5 errors / unknown Quickshell types | Arch | Use `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml`, not `/usr/bin/qmllint` |
| New component "is not a type" | Arch | Add it to the folder's `qmldir` |
| Clicks across the top strip are swallowed | Arch | The surface lacks `mask: Region { item: ... }` |
| Dispatch has no effect | Arch | Use the `hl.dsp.*` Lua bridge, not `Hyprland.dispatch` |
| `qs -c notch` says config not found | Arch | Create the symlink from First run |

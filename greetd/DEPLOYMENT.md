# greetd deployment and SDDM fallback

This runbook installs the notch greeter as the display manager on the
development machine. SDDM stays installed as the fallback and can take over
again with the commands below. Editing PAM, the VT or user groups is out of
scope unless it is agreed separately.

## Verified so far

- The visual preview was reviewed. `make check` passed before the latest
  parity commits.
- The real greetd client, PAM and a disposable account passed the headless
  test in `scripts/test-greetd-pam.mjs`. This did **not** start a real graphical
  login, switch a VT, test the keyboard or start Hyprland.
- On the development machine, `greetd`, Quickshell, Qt Virtual Keyboard and
  `cage` 0.3.1 are installed. The maintainer installed Cage explicitly.
- Cage started and exited successfully under the existing Wayland session with
  `WLR_BACKENDS=wayland` and a short-lived `/usr/bin/true` child. This tested
  an **unauthenticated nested compositor only**: it did not start the greeter,
  acquire a physical seat, change VT or test direct DRM/session activation.
- The Quickshell visual mock also completed its automatic success path inside
  nested Cage using `scripts/test-greetd-protocol.mjs` and its guarded private
  fake socket. The mock requested `mock-session-not-executed`; it did not use
  PAM, real credentials, a real session command or a physical VT. This used
  the mock wrapper, not the real `greetd-shell.qml` entrypoint, and did not
  measure fullscreen coverage or keyboard interaction.
- The real `greetd-shell.qml` entrypoint also completed its automatic success
  path inside nested Cage against a private fake greetd socket. In one test the
  reported window and nested output were both 630×844 logical pixels, rather
  than the QML initial size of 1280×720. This is **one nested-output result**,
  not proof of coverage on a physical VT, at other resolutions, with multiple
  monitors, or of interactive keyboard behavior. The test never executes the
  requested mock session command.
- A separate opt-in test explicitly fullscreened only its own nested Cage
  window in Hyprland and compared the monitor, Cage window, nested output and
  greeter window. On the development machine the monitor reported 2880×1800
  at scale 2 (1440×900 logical); Cage, its output and the greeter all reported
  1440×900. This is a nested compositor test under the running session, not a
  direct DRM/physical-VT login or a test of a fractional scale.
- At the time of inspection SDDM was active/enabled, greetd inactive/disabled,
  and `/etc/systemd/system/display-manager.service` pointed to SDDM. Recheck
  these facts before any future switch; do not rely on this snapshot.
- The currently staged SDDM directory is group `sddm`, mode `2750`, and its
  theme and background files are mode `0640`; `greeter` is not in that group.
  These mode/group facts imply no access through ordinary Unix permissions;
  an actual read as `greeter` has not yet been performed. The original saved
  wallpaper is inside a private home directory. Do not grant home traversal or
  change groups to work around this without a reviewed deployment decision.
- A separate `/var/lib/quickshell-notch-greetd` was created on the development
  machine with owner `deadlock`, group `greeter`, mode `2750`. The publisher
  staged the current GIF and palette as `0640` files, and the maintainer
  confirmed that `sudo -u greeter` could read the manifest and the entire image.
  This verifies file access only, not a graphical login.
- The active Hyprland session is on `tty1`, and the installed greetd config
  also specifies `vt = 1`; the packaged service conflicts with
  `getty@tty1.service`. Do not start that service to perform a parallel test.
  A separate greetd process, configuration, socket and explicitly verified
  spare VT are required, without altering `/etc/greetd/config.toml`.
- The maintainer confirmed access to `tty3` with Ctrl+Alt+F3. A getty is
  running there; credential-based login and the return shortcut to `tty1`
  were not independently verified. Reserve `tty3` for recovery, not testing.
- A minimal copy of the real greeter and its relative imports/resources passes
  the fake-socket headless login test (`tests/qml/greetd-real.mjs`).
- That copy is installed at `/usr/local/share/quickshell-notch-greetd` as a
  root-owned system tree: 16 files, every directory `0755`, every file `0644`,
  owner `root:root`. Their SHA-256 digests match the staged tree and the
  repository working tree. The first copy was made with `cp -r`, which kept the
  private `0700` mode of the source directory; the maintainer corrected only
  the root directory to `0755`.
- `greeter` (uid 947, groups `greeter` and `video`) is not the owner and not in
  the owning group, so access depends on the world bits above; no ACLs are set
  and AppArmor/SELinux are not enforcing. This implies read/traverse access but
  an actual read of this installed tree as `greeter` has not been performed,
  because privileged commands require the maintainer's password.
- The **installed** entrypoint, not only the repository one, passed the
  fake-socket headless test with `NOTCH_GREETD_VISUAL_DIR` pointing at the
  published assets. This proves the deployed bytes load and authenticate; it
  does not prove graphical rendering, a physical VT or a real session launch.
- A throwaway greetd instance was then run on `vt = 8` (above systemd's
  `NAutoVTs = 6`) from a temporary configuration via `systemd-run`, leaving
  SDDM, `/etc/greetd` and the display-manager selection untouched. The
  installed tree rendered on the physical panel and accepted keyboard input;
  greetd opened a logind session for `greeter`
  (`pam_unix(greetd:session): session opened for user greeter`), which is what
  supplies the seat, DRM node and input devices, so neither `seatd` nor extra
  groups are required. A real account authenticated and `start_session` ran a
  placeholder command (`/usr/bin/sleep 5`), not a desktop session.
- That test exposed a scale problem: cage leaves its output at scale 1, so on
  a 2880×1800 panel everything renders at half the size it has on the desktop
  (Hyprland scale 2). `greetd/launch-greeter.sh` now exports
  `QT_SCALE_FACTOR` from `NOTCH_GREETD_SCALE` (default 2; it must match the
  monitor scale) and the login surface fills the compositor's logical screen
  instead of staying 1280×720. The maintainer confirmed the corrected scale.
- A second physical-VT run confirmed the scale matches the desktop, but cage
  decorated the maximised client with its own title bar and close button.
  `launch-greeter.sh` now starts cage with `-d` so the surface has no
  decorations; `-s` keeps the VT-switch escape hatch. The maintainer confirmed
  the undecorated surface.

## Current deployment

The deployable tree is `greetd/tree.txt`; `sudo make deploy-greeter` installs
it as root into `/usr/local/share/quickshell-notch-greetd` (directories
`0755`, files `0644`, launcher `0755`). The greeter reads the published
wallpaper and palette from `/var/lib/quickshell-notch-greetd`.

`greetd/config.toml.example` is the system configuration: `vt = 1`,
`user = "greeter"` and the installed launcher as `command`. Back up the
packaged file first; it runs `agreety`.

Cutover, run once:

```sh
sudo install -m 0644 greetd/config.toml.example /etc/greetd/config.toml
sudo make deploy-greeter
sudo systemctl disable sddm
sudo systemctl enable greetd
systemctl is-enabled sddm greetd
readlink /etc/systemd/system/display-manager.service
# reboot when convenient
```

`systemctl enable greetd` points `display-manager.service` at greetd through
the unit's `Alias`. SDDM must be disabled first so the same alias cannot
belong to both. The greeter's environment comes from PAM
(`system-local-login`), which opens a logind session for `greeter` and starts
the authenticated account's user manager.

Launcher defaults, overridable through the environment:

| Variable | Default |
| --- | --- |
| `NOTCH_GREETD_VISUAL_DIR` | `/var/lib/quickshell-notch-greetd` |
| `NOTCH_GREETD_SCALE` | `2` (must match the Hyprland monitor scale) |
| `NOTCH_GREETD_SESSION` | `uwsm start -e -D Hyprland hyprland.desktop` |

The real greeter's visual-directory interface is documented in
[`preview/README.md`](preview/README.md).

### Asset publication

The existing SDDM publisher uses atomic replacements and mode `0640` for its
theme and background files. Granting an ACL to one existing file is therefore
not a durable sync strategy: that file may be replaced on the next wallpaper
update. Nor is pointing at the current private wallpaper path a safe assumption.

The opt-in publisher `shell/scripts/greetd-sync.py` copies the selected image or
video to a content-addressed immutable filename, then atomically replaces a
single `visual.json` containing that filename and the two palette colours.
The greeter reads the manifest once, so an update cannot mix its wallpaper and
palette. Older wallpaper files are deliberately retained for readers that
already loaded an earlier manifest; no automatic garbage collection is in
place, so disk usage grows when different wallpapers are published. Default
notch width remains 300; the legacy files still work when no valid manifest is
present, but their separate reads do not offer the same atomic guarantee.

Publication is disabled unless the shell receives an explicit absolute
`NOTCH_GREETD_DATA_DIR` or an absolute path in
`$XDG_STATE_HOME/quickshell-notch/greetd-target.txt` (the environment takes
precedence). The real greeter reads `NOTCH_GREETD_VISUAL_DIR`.
The output must already exist, be owned by the publishing user, have no
group/other write permission, and contain no symlink components. Files are
created with mode `0640`, inheriting the directory's group. The deployment must
ensure that group and every parent directory are readable/traversable by the
greeter, without granting access to the private home. The directory must be
dedicated to greetd and not shared with SDDM or untrusted writers.

On the development machine the target file names the prepared directory, and
the active shell reloaded the implementation after its submodule was updated.
A real wallpaper change has not yet been observed after this update; the next
one should be checked against the published manifest. If
publication fails, the prior manifest and image remain in
place. A crash can leave an unused staged or wallpaper file. The publisher does
not provide power-loss durability guarantees and changes no service.

## Post-cutover checks

1. Sign in at the greeter; the notch shell should appear with the desktop
   session, wallpaper and notch continuity.
2. Log out (or run `hyprctl dispatch exit`): greetd must restart the greeter.
3. Try a wrong password and a retry. Use the power buttons only when a restart
   is acceptable; they run `systemctl poweroff` / `reboot` as `greeter`.
4. Still deferred: fingerprint prompts, multi-monitor layouts, fractional
   scales and a session selector beyond Hyprland.

## Rollback to SDDM

From `tty3` (a getty is available there):

```sh
sudo systemctl disable greetd
sudo systemctl enable sddm
sudo systemctl start sddm   # or reboot
```

If the greeter cannot start at boot, add `systemd.mask=greetd.service` to the
kernel command line, boot to a text console and run the commands above.

- Preserve `/etc/greetd/config.toml.packaged` and the recorded
  `display-manager.service` target before any change.
- Do not run broad cleanup, reset PAM, delete user files or stop an active
  graphical session as a generic recovery step. Verify SDDM and the login path
  after recovery.
- If the machine cannot reach a TTY or remote shell, boot into the previously
  verified rescue environment and restore the same selection there.

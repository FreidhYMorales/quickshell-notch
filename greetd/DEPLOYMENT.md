# greetd deployment and SDDM recovery: preparation only

This is a **draft runbook, not an installation procedure**. Keep SDDM enabled
and active, and greetd disabled and inactive, until the open checks below are
resolved and the maintainer explicitly approves a display-manager switch.
The repository and the existing SDDM theme remain available as a fallback.

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
  the fake-socket headless login test (`tests/qml/greetd-real.mjs`); it is not
  yet installed as a root-controlled system tree or tested as `greeter`.

## Blockers before a graphical test

| Check | Required outcome |
| --- | --- |
| Compositor | Cage and the visual mock have run nested. Verify the real entrypoint, direct seat activation and the actual compositor/session lifecycle with greetd before choosing it for deployment. |
| Screen coverage | Nested Cage tests measured the real window equal to 630×844 and fullscreen 1440×900 nested outputs. The QML starts at 1280×720 and has no explicit fullscreen request; direct physical-output coverage and input remain **unverified**. Multi-monitor and fractional-scale validation remain deferred. |
| Recovery | Confirm a working second TTY, local credentials and, if applicable, remote access. Record the current display-manager symlink and original configuration before a switch. |
| Deployment path | Stage the greeter in a root-controlled directory traversable/readable by `greeter`. Its root entrypoint must retain its relative `greetd/`, `shell/logic/` and `sddm/notch/` assets. Do not loosen private home-directory permissions. |
| Visual assets | A dedicated directory and a manual read as `greeter` are verified on the development machine. Deploy the updated shell and configure `NOTCH_GREETD_VISUAL_DIR` for the greeter; verify actual graphical loading. Missing assets fall back to defaults. |
| Keyboard and power | Test Qt Virtual Keyboard under the chosen compositor, including its input-method environment, and verify that power actions are authorized. Never invoke power actions from automated tests. |
| Authentication | Keep the PAM stack unchanged without separate approval. The current host's `greetd` PAM stack includes `pam_fprintd` before password authentication; fingerprint configuration is deferred. Test wrong password, retry, timeout and success with a disposable account first. |
| Session and handoff | Confirm that `Hyprland` is the intended session command, the session actually starts after greeter exit, and wallpaper/notch continuity is acceptable. The selector currently offers Hyprland only; the shell's idle notch width is dynamic while the greeter uses presets. |

No greeter configuration is supplied as ready-to-install: the compositor,
deployment location, asset publication and graphical behavior are not yet
verified. The real greeter's visual-directory interface is documented in
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
A real wallpaper change has not yet been observed after this update. If
publication fails, the prior manifest and image remain in
place. A crash can leave an unused staged or wallpaper file. The publisher does
not provide power-loss durability guarantees. No service was changed.

## Proposed future test sequence

1. Complete the blockers and agree on a specific test plan, target VT and
   exact commands. A graphical greeter can capture keyboard input and a VT;
   warn the user immediately before running it.
2. Prefer an isolated test that leaves SDDM running and does not take its VT.
   Prove the compositor, permissions and a disposable-account login first.
   Stop and recover if a separate safe VT cannot be established.
3. Review results and only then ask for separate explicit approval to change
   the default display manager. Never restart or stop the active SDDM session
   as an implicit part of preparation.

## Recovery contract

Before any approved switch, prepare and verify a rollback with the maintainer:

- Preserve the original greetd configuration and the exact current
  `display-manager.service` target; record backup locations and permissions.
- From a working TTY or remote shell, stop the **test instance** if one was
  started, restore any files and display-manager selection changed by that
  test, and return control to SDDM using the reviewed procedure for that test.
- If the machine cannot reach a TTY or remote shell, boot into the previously
  verified rescue environment and perform the same restoration there.
- Do not run broad cleanup, reset PAM, delete user files or restart an active
  graphical session as a generic recovery step. Verify SDDM and the login path
  after recovery.

Exact privileged commands are deliberately deferred until the compositor,
test isolation and switching procedure have been verified and approved.

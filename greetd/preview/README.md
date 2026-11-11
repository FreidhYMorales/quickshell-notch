# greetd greeter prototype

Three pieces share one login surface (`preview/Main.qml`):

- `scripts/test-greetd-preview.sh` — pure visual simulation. No greetd, PAM,
  session or real credential. The two buttons simulate success and failure.
- `node scripts/test-greetd-protocol.mjs` — the same surface driven by
  Quickshell's real greetd client against a private fake Unix socket. Still no
  real credential: both buttons send a fixed dummy secret.
- `greetd-shell.qml` — the real greeter entrypoint. It refuses to start unless
  `GREETD_SOCK` is set, reads accounts from `/etc/passwd`, sends the typed
  password to PAM through greetd and compresses into the notch while PAM
  authenticates. It requests the session command (`Hyprland`) only after both
  `readyToLaunch` and compression. It is not enabled or installed anywhere yet.

The surface keeps the shared concave ear mask, the notch width and palette
staged for the SDDM greeter, and the saved wallpaper (still image, GIF or muted
video). The account list uses the GECOS real name. It tries the standard
AccountsService icon cache, falling back to the vector silhouette if the
greeter cannot read an image; it does not require the AccountsService daemon.

## Visual checks

Run `./scripts/test-greetd-preview.sh` from the repository root for the
simulation and `node scripts/test-greetd-protocol.mjs` for the fake-socket
version. Both open a normal window and never authenticate anything. The visual
preview starts with the clock; click or press a key to open the login. Click the
arrow or press Enter to simulate success; press Ctrl+Shift+F to simulate a
failure. Its password field is disabled and its power controls do nothing.
Close the window normally to exit.

Do not enter real credentials into either command: the field is only real
inside `greetd-shell.qml`, which greetd starts.

## Greeter visual settings

The real entrypoint accepts an administrator-provided absolute directory in
`NOTCH_GREETD_VISUAL_DIR`. It reads optional `theme.conf` and `theme.conf.user`
(the SDDM `[General]` palette and notch presets, with the latter taking
precedence) and `wallpaper.txt` (one absolute wallpaper path).
Both files and the wallpaper must be readable by the greeter account. Missing
or invalid values fall back to the default palette and no wallpaper. The
existing `NOTCH_GREETD_PREVIEW_*` variables override these settings when set.
This only supplies the runtime interface: it does not deploy files, change
greetd configuration or grant access to private home directories.

The footer offers a styled session selector, a virtual keyboard, back, power
off and reboot. The selector currently has only Hyprland: unlike SDDM, greetd
does not provide a session model, and other desktop sessions are not launched.
Real power buttons call `systemctl` as the greeter and may require logind/polkit
authorization; their real effect has not been tested. Preview buttons cannot
power off or reboot the machine. Qt Virtual Keyboard must be installed and the
compositor must enable the `qtvirtualkeyboard` input method for typing to work.
In the visual simulation the keyboard button shows its panel for inspection,
but the password field remains disabled and cannot accept real credentials.

## Tests

`node --test tests/qml/greetd-preview.mjs` covers the simulation order and the
visual tokens. `node --test tests/qml/greetd-protocol.mjs` covers informational
messages, recoverable errors, a dummy password prompt, final success/failure,
the animation-before-launch ordering, an unapproved socket and a retry.
`node --test tests/qml/greetd-real.mjs` runs the real entrypoint against a
private fake socket: success compresses before `start_session`; failure
expands with the error and never launches. The fake server never executes the
requested command.

The optional nested Cage geometry check is run from an existing Wayland
session with `NOTCH_GREETD_CAGE_TEST=1 node --test --test-name-pattern='nested Cage reports' tests/qml/greetd-real.mjs`.
It opens a nested window that may receive keyboard focus. It uses a private
fake socket and dummy credentials, never executes the mock session command,
and does not validate a physical VT or a direct DRM/seat session.

For an opt-in fullscreen variant on Hyprland, run
`NOTCH_GREETD_CAGE_FULLSCREEN=1 node --test --test-name-pattern='fullscreen nested Cage' tests/qml/greetd-real.mjs`.
It temporarily fullscreens only its own Cage window and may take keyboard
focus; it does not change the monitor resolution, scale, VT or display manager.

Quickshell 0.3 sends a cancellation request after a final failure and logs its
reply as an unexpected response: greetd releases the failed session but its
PAM worker has already exited, so the cancellation comes back as a connection
error. That is only the cancellation acknowledgement: a retry starts a fresh
session, animates and then requests the simulated launch, which the tests
cover.

## Real PAM test

`sudo node scripts/test-greetd-pam.mjs` checks the real greetd and PAM stack
without touching the running session or the display manager. It starts a
second greetd with a temporary config on `vt = "none"` (no VT, keyboard or
compositor), creates a throwaway account with a random password that only
lives in memory, and then:

1. a wrong password must come back as `auth_error`, and the client must cancel
   that session before retrying;
2. the right password must authenticate, and the client cancels it;
3. the real QML greeter must reject a wrong password and show the failure;
4. the real QML greeter must authenticate, compress, request the session, and
   the session must actually run as the throwaway user (a marker script).

The account, its home, its faillock entry, the temporary config and the second
greetd are removed on exit, including on failure. The installed
`greetd.service` is untouched and SDDM stays the active display manager.

The QML phase runs `qs` as root because the repository lives under a private
home; greetd still starts the requested session as the throwaway user. Its
credentials reach the greeter through the environment and are never logged.
The placeholder greeter only exits when the test asks it to, because greetd
keeps a requested session scheduled until the greeter exits.

The greetd PAM service includes `system-local-login`, so the test also shows
whether `pam_fprintd` runs before the password. Fingerprint support is still
deferred until after the reinstall.

## Not done yet

- Deployment preparation and the recovery contract are in
  [`../DEPLOYMENT.md`](../DEPLOYMENT.md). They do not authorize activation.
- No deployment under `cage`, no greetd config and no installed theme.
- Real power authorization, virtual keyboard input and avatar permissions need
  testing in the deployed greeter environment; fingerprint and multi-monitor
  placement remain deferred.
- A stalled PAM attempt expands and shows a pending message after 20 seconds.
  It is not cancelled, and another login cannot start until PAM responds. A
  required interactive PAM prompt also expands the greeter and remains
  answerable to avoid blocking authentication.

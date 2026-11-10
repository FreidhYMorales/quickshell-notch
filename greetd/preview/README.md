# greetd greeter prototype

Three pieces share one login surface (`preview/Main.qml`):

- `scripts/test-greetd-preview.sh` — pure visual simulation. No greetd, PAM,
  session or real credential. The two buttons simulate success and failure.
- `node scripts/test-greetd-protocol.mjs` — the same surface driven by
  Quickshell's real greetd client against a private fake Unix socket. Still no
  real credential: both buttons send a fixed dummy secret.
- `greetd-shell.qml` — the real greeter entrypoint. It refuses to start unless
  `GREETD_SOCK` is set, reads accounts from `/etc/passwd`, sends the typed
  password to PAM through greetd, compresses into the notch when
  `readyToLaunch` arrives and only then requests the session command
  (`Hyprland`). It is not enabled or installed anywhere yet.

The surface keeps the shared concave ear mask, the notch width and palette
staged for the SDDM greeter, and the saved wallpaper (still image, GIF or muted
video). The account list uses the GECOS real name; there are no avatars or
AccountsService lookups yet.

## Visual checks

Run `./scripts/test-greetd-preview.sh` from the repository root for the
simulation and `node scripts/test-greetd-protocol.mjs` for the fake-socket
version. Both open a normal window and never authenticate anything. A simulated
success closes the window after the notch frame; close it normally to exit.

Do not enter real credentials into either command: the field is only real
inside `greetd-shell.qml`, which greetd starts.

## Tests

`node --test tests/qml/greetd-preview.mjs` covers the simulation order and the
visual tokens. `node --test tests/qml/greetd-protocol.mjs` covers informational
messages, recoverable errors, a dummy password prompt, final success/failure,
the animation-before-launch ordering, an unapproved socket and a retry.
`node --test tests/qml/greetd-real.mjs` runs the real entrypoint against a
private fake socket: success compresses before `start_session`; failure
expands with the error and never launches. The fake server never executes the
requested command.

Quickshell 0.3 sends a cancellation request after a final failure and logs its
reply as an unexpected response because the session is already inactive. That
is only the cancellation acknowledgement: a retry starts a fresh session,
animates and then requests the simulated launch, which the tests cover.

## Not done yet

- No real PAM or greetd test: that needs enabling greetd, which is out of
  scope without explicit approval. SDDM stays the active display manager.
- No deployment under `cage`, no greetd config and no installed theme.
- Avatars, fingerprint and multi-monitor placement are out of scope here.
- The greeter cannot cancel PAM; a stalled attempt has no timeout yet.

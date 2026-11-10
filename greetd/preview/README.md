# greetd visual simulation

Run `./scripts/test-greetd-preview.sh` from the repository root. This opens a
normal Qt Quick window; it does not connect to greetd, PAM, SDDM or logind, and
it cannot launch a session. Do not enter real credentials into a simulation.

The success button simulates authentication, then plays the exit morph and
simulates session launch. The failure button compresses, shakes the red lock,
and expands back with a simulated error without launching. The window resets
after the success demonstration. The shared saved wallpaper is used for still
images, GIFs and supported videos (muted), and the notch frame takes its width,
accent and foreground from the staged SDDM palette (`theme.conf.user`). This is
an early visual mock, not the final notch geometry or a real Quickshell greetd
integration.

The following stage needs a separate real greetd/PAM test with a recovery
path. It must not activate or replace SDDM without explicit approval.

For an interactive protocol preview, run `node scripts/test-greetd-protocol.mjs`.
This uses the same window through Quickshell's real greetd client, but connects
only to a private fake Unix socket. Both buttons send a fixed dummy secret; the
input field is not used for authentication. A simulated success closes the
preview after the notch frame; close the window normally to exit at any time.

`node --test tests/qml/greetd-protocol.mjs` tests informational messages,
recoverable errors, a dummy password prompt, final success/failure, the visual
animation-before-launch ordering and rejection of an unapproved socket. The
mock server never executes the session command. These tests do not connect to
a real daemon, send real credentials, or verify PAM.

Quickshell 0.3 sends a cancellation request after a simulated final failure;
its reply can be logged as unexpected. The retry ordering and real PAM behavior
remain open questions and this preview is not suitable as a login manager.

# Story 11: Polkit prompts

## Story

11. As a user, I want polkit password prompts in the centre notch so that apps can ask for admin rights.

## Acceptance criteria

- [ ] Given an application requests polkit authentication, when the request arrives, then the centre notch on the focused monitor takes exclusive keyboard focus and shows the action message, the requested input, and Cancel/Authenticate controls above other centre states; any power confirmation in progress is cancelled.
- [ ] Given an authentication prompt, when I submit a response, then it is sent to the requesting authentication flow, secret input is masked and never logged or persisted, and success closes the prompt while failure is shown without granting access and permits any retry offered by the flow.
- [ ] Given an active authentication request, when I cancel it, the session locks, or its monitor is removed, then the prompt closes and the request is cancelled without authorizing the action; if the flow ends externally, the prompt closes and the previous state returns, while locking or monitor removal closes the affected keyboard state.

## Plan

- Connect authentication requests and their lifecycle to the centre state and focused monitor.
- Present the action and response controls with exclusive focus, handling success, failure and cancellation.
- Preserve state priority, monitor removal and lock behaviour; keep secrets out of logs and storage.
- Cover the flow and safety boundaries with automated tests and verify a real request manually.

## Out of scope

- Lock screen implementation and cutover between the old and new shells.
- Changes to polkit authorization policies or a separate authentication application.

## Suggestions (your call)

- Reuse the old shell's polkit service and form as references; they already wrap Quickshell's agent and handle flow messages and response visibility.

## Size

normal
Risk: item 2, 5 (authentication and secrets; runtime polkit agent registration)

## Log

- L1 request: Load the `flow-story` skill and follow it. 11
- Approved the integration and manual test list; baseline `make check` passed on main before changes.
- First integration scenario needs smaller TDD steps to stay within the step size limit; awaiting approval.
- Message step: red test 96257b8, green implementation e91cce7; focused test and `make check` passed.
- Input step stopped with an uncommitted failing integration test: its fixture and runner exceed the step size limit. Awaiting direction.
- User approved the input test size exception; red 9b6975e, green 42c8b04, focused test and `make check` passed.
- Controls: red 4dc4f95, green 2a3d833, focused test and `make check` passed; labels are not yet fully connected.
- Cancel: red 7e41010; focused test passes with uncommitted implementation. Two `make check` attempts stopped at QML formatting; awaiting direction before another attempt.
- User approved continuing; cancel green 3752128, focused test and `make check` passed.
- Submit integration test is red and uncommitted; fixture plus runner exceed the step size limit, so approval is needed before proceeding.
- User approved submit test size exception; red cf1116f, green 4269237, focused test and `make check` passed.
- Incoming requests are cancelled while locked (db973e9 → 3ed5130) or without a valid monitor (5c5adc4 → f8fcb1e); `make check` passed.
- Private-bus registration test loads the real centre store but fails because the agent is not registered. Its uncommitted fixture exceeds the step size limit; awaiting direction.
- User approved registration test size exception; red 8d340aa, green c435783, focused test and `make check` passed. Agent flow is not yet connected; do not run this partial branch as the active shell.
- Private authority prototype successfully delivered a real authentication request to Quickshell. Offscreen has no focused monitor; test cancellation before process exit before wiring the flow.
- No focused monitor: red 10ca8f0, green a732f1f; focused monitor: red 7b926d1, green be6bee6; external flow end: red e5fe4af, green 58c57ec. Each focused test and `make check` passed.
- Security: uncommitted QML integration test shows a cancelled response persists into the next request. Fixture exceeds the step size limit; awaiting direction.
- Response clearing: red 9636c15, green 997874c. Error message: red 8078454, green 5a71eeb. Error height loop: red 595da0b, green 55fa98a.
- QML check registration: red e95e3dd, green 3e087f2; full `make check` passed with 11 polkit QML probes. Two real-agent tests under `tests/` require Quickshell and Python D-Bus, unavailable in the current CI container. Awaiting approval to move them without changing their assertions.
- Field and idle button tint (user: "like the notifications panel"): red 4b0d612, green b25eb73; `make check` passed. Awaiting visual check.
- Fingerprint prompt width 360→460 (password prompt unchanged): red 56b2dbf, green 5cd3bd3; `make check` passed. User approved the field tint visually.
- Side padding 18→36 (top unchanged): red e351cae, green 94cdaa3; `make check` passed.
- User approved the visual result (field tint, fingerprint width, side padding).
- Fingerprint icon: red b22a512, green 9cd0e69. Scan line: red b2e2b11, green 0f70792 (first `make check` hit a timeout in polkit-flow-ended.mjs; the test passed 3/3 alone and the full rerun passed). Password regression 79036b7 passed immediately. Awaiting visual check.
- Icon order (message, icon, hint): red 6fc62a5, green ad663ef; `make check` passed.
- Faillock lockout: real-flow probes ran system PAM as the developer, so each cancelled probe was a failed login and three locked the account for 10 min (correct passwords then failed and the flow restarted at fingerprint). Guard red 8dbb08d, green ab74b46 (probes authenticate as `nobody`); `make check` passed with an empty faillock tally. Two runs before it failed once each in polkit-enter and polkit-submit (real input; both pass alone), not caused by this change.
- Verifier (fresh, read-only): C2 and C3 pass; C1 gap: fingerprint prompts had no Cancel or Escape while holding exclusive keyboard. User approved the fix. Fingerprint cancel: red b5b9a35, green 8229b7d. Escape: red e3e066c, green 7821f2d; password Escape regression 14da179 passed immediately. `make check` passed. Low findings left open: flow switch without null may carry typed text; identity guard is a literal string match; no automated log check for secrets.

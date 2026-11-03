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

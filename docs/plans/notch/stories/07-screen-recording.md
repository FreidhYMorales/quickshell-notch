# Story 07: Screen recording from the control center

## Story

07. As a user, I want to start and stop screen recording from the control center and see the red dot on the notch while recording so that I know I am recording. Requires: #16

## Acceptance criteria

- [ ] Given recording is idle and the recorder is available, when I start it from the control center, then it records the full screen with system audio and the idle notch shows a red dot while recording is active.
- [ ] Given a recording is active, when I stop it from the control center, then the recording is finalized and saved without overwriting an existing recording, and the red dot disappears when recording ends.
- [ ] Given recording cannot start or ends unexpectedly, when the failure occurs, then I am informed and the control center and red dot do not indicate that recording is still active.

## Plan

- Reuse the existing recording approach for full-screen capture and system audio, including safe finalization.
- Connect the control center action and idle-notch indicator to the recording state.
- Cover state transitions and failures with tests; verify a real recording manually.
- Assumption for approval: save MP4 recordings in the old shell's recordings directory, `~/Videos/Recordings`, honoring its existing `QS_RECORDINGS_DIR` override.

## Out of scope

- Region or window recording, microphone recording, and controls to select capture or audio modes.
- Expanded recording indicator, elapsed time and stop control in the center notch.
- Other control center tiles and session actions.

## Suggestions (your call)

- The existing idle notch already displays a red dot from the recorder state; reuse it rather than adding another indicator.

## Size

normal
Risk: item 1, 6 (recording files must not overwrite existing data; real capture and audio require manual verification)

## Log

- L1 request: Load the `flow-story` skill and follow it. 07
- L2 scope: user approved full-screen recording with system audio; region, window and microphone selection deferred.
- L3 pairing: user approved the proposed test list. The first integration test spans the control, recorder process and indicator; pause to propose smaller steps before writing tests or code.
- L4 idle control: test c99c25f failed with `recording control: missing`; 337126c shows the idle control and `make check` passed. The user approved continuing with activation. Starting a real recorder before a stop control exists would leave an unfinished user-facing action; pause to propose a safe isolated recorder step.
- L5 isolated recorder: user approved testing start and stop without connecting the UI. Two attempts to set up the QML probe failed because `Recorder` was not resolved; neither failure is a valid red. Test files remain uncommitted; no recorder implementation was written.
- L6 isolated probe: user approved investigating the setup; importing the services namespace resolves the singleton. Test commit 50a2986 fails with `recording service: did not start`. The test step is 67 lines, exceeding the approximately 50-line stop rule; pause for direction before production changes. The red marker remains in place.
- L7 green attempt: user accepted the 67-line test-size exception. Two runs still failed with `recording service: did not start`; temporary instrumentation produced no evidence that `Recorder.start()` was invoked. The test may be defective; no test was changed. Recorder implementation remains uncommitted and incomplete; stop under the two-attempt rule. Red marker remains.
- L8 diagnosis: user approved investigation. The test's relative import resolves to `qrc:/qs-blackhole` outside the Quickshell test config root; it does not load the real recorder. A temporary component loaded by absolute file URL from the service tree observed `typeof Recorder.start` as `function` and `recording` as `false`. Diagnostic files were removed; the committed test needs correction and its original red is invalid.
- L9 corrected probe: user approved correcting the committed test. The incomplete implementation was saved separately and the original service restored; corrected test d319bc7 loaded the real service and failed with `recording service: did not start`. Restoring the earlier implementation made the test and `make check` pass; the test files match d319bc7. The implementation was originally written before this valid red, a historical Strict TDD exception requiring user direction. The implementation remains uncommitted and the red marker remains.
- L10 exception: user explicitly accepted the historical Strict TDD exception in L9; the acceptance does not change the actual ordering. Implementation committed as 36ae65c. Isolated fake-process start/stop test and `make check` passed; UI connection, actual capture, failure handling and collision verification remain.
- L11 directory: test a09c53b failed when the nested output directory was missing; 9efbdfc creates it before recording. The existing-directory test and `make check` passed.
- L12 UI probe: user approved connecting the control and dot. The uncommitted integration probe exceeds the approximately 50-line step limit and its first failure did not report a specific QML assertion; no valid red or UI implementation yet. Pause for direction.
- L13 split UI probe: user approved separating start and stop. The uncommitted start probe now reports `recording start: red dot missing`, but its setup and test still total 74 lines, above the step limit. No UI production code was written; pause before committing the test.
- L14 start UI: user accepted the 74-line probe exception. Test 89746b1 failed with `recording start: red dot missing`; temporary forced recording state proved the probe detects the dot. Code a588092 connects start, with focused test and `make check` passing. Stop was not yet connected.
- L15 stop probe: user approved the stop step. The new uncommitted test fails with `recording stop: red dot still visible`; it spans 69 lines, above the approximately 50-line step limit. No stop UI implementation was written; pause for direction.
- L16 stop UI: user accepted the 69-line probe exception. Test 531165f failed with `recording stop: red dot still visible`; code a9144cd toggles stop and the focused test and `make check` passed.
- L17 failure probe: user approved checking failure to start. The uncommitted test verifies the fake recorder ran and exited unsuccessfully, but no visible failure notification appeared; it is 66 lines, above the step limit. This tests an immediate nonzero exit, not a missing executable. No failure handling was written; pause for direction.
- L18 nonzero exit: user accepted the 66-line probe exception. Test 669f343 failed with `recording failure: notification missing`; fix 34b6bb4 posts a notification on nonzero exit. Focused test and `make check` passed.
- L19 missing executable: user approved testing an absent recorder. A private PATH with necessary test tools but no recorder produces Quickshell's failed-to-start warning and `missing recorder: notification absent`. The test remains uncommitted and exceeds the step size limit; pause for direction. No missing-executable fix was written.

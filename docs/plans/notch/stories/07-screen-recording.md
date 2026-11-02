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

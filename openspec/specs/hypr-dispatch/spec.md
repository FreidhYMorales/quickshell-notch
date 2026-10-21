# Hypr Dispatch Specification

## Purpose

`Hypr` service: the single wrapper over `hl.dsp.*` so bridge changes touch one file.

## Requirements

### Requirement: Single entry point

All compositor dispatches MUST go through one `Hypr` dispatch function; no other file calls `hl.dsp.*`.

#### Scenario: Search
- GIVEN the shell sources
- WHEN searched for `hl.dsp`
- THEN matches exist only in the Hypr service

### Requirement: Dispatch call

`dispatch(name, args)` MUST invoke the matching `hl.dsp.*` call and return success or failure without throwing.

#### Scenario: Valid
- GIVEN a known dispatcher
- WHEN dispatched
- THEN the call is forwarded with its arguments

#### Scenario: Unknown
- GIVEN an unknown dispatcher name
- WHEN dispatched
- THEN it returns failure AND logs a warning

### Requirement: Smoke safety

Under `NOTCH_SMOKE=1`, `dispatch` MUST NOT reach the compositor.

#### Scenario: Smoke
- GIVEN `NOTCH_SMOKE=1`
- WHEN dispatched
- THEN no compositor call is made

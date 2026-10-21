# Session Service Specification

## Purpose

`Session` singleton: the only contract through which lock requests and lock state reach the shell.

## Requirements

### Requirement: Contract

`Session` MUST expose a `lockRequested` signal and a boolean `locked`, initially false.

#### Scenario: Defaults
- GIVEN the shell just started
- WHEN `Session.locked` is read
- THEN it is false

### Requirement: Lock request

Emitting a lock request MUST fire `lockRequested` once per request and MUST NOT itself change `locked`.

#### Scenario: Request
- GIVEN a listener on `lockRequested`
- WHEN a lock is requested
- THEN the listener fires once AND `locked` is unchanged

### Requirement: Locked flag

`locked` MUST change only through the session's setter (tests and stubs until phase 7) and MUST notify on change.

#### Scenario: Set
- GIVEN `locked = false`
- WHEN set to true
- THEN a change notification fires AND consumers see true

### Requirement: No Visibilities dependency

Consumers MUST NOT depend on the old `Visibilities` singleton.

#### Scenario: Search
- GIVEN the shell sources
- WHEN searched for `Visibilities`
- THEN no references exist

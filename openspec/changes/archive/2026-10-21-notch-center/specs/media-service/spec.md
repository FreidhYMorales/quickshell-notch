# Media Service Specification

## Purpose

Reactive MPRIS data and pure player selection for the expanded notch.

## Requirements

### Requirement: Reactive player data

The `Mpris` service MUST expose `hasPlayer`, the active player's title, album, artist, art URL, playback state and prev/play-pause/next controls. It MUST update from player signals and MUST NOT poll.

#### Scenario: Player appears (manual)
- GIVEN no player
- WHEN a player starts
- THEN `hasPlayer` becomes true without a restart

#### Scenario: Player quits (manual)
- GIVEN one player
- WHEN it quits
- THEN `hasPlayer` becomes false

### Requirement: Player selection

A pure `selectPlayer(players[{id, state}])` MUST return the id of the first player whose state is `playing`; otherwise the first player; for an empty list `null`.

| players (id:state) | result |
|---|---|
| (empty) | null |
| a:paused | a |
| a:paused, b:playing | b |
| a:playing, b:playing | a |
| a:paused, b:stopped | a |

#### Scenario: Prefers playing
- GIVEN a:paused and b:playing
- WHEN selected
- THEN b is returned

#### Scenario: Switch when playback moves
- GIVEN a:playing, b:paused
- WHEN the list becomes a:paused, b:playing
- THEN b is returned

### Requirement: Controls

Prev, play/pause and next MUST act on the selected player only.

#### Scenario: Play/pause (manual)
- GIVEN two players, b playing
- WHEN play/pause is pressed
- THEN only b toggles

# OSD Notch Specification

## Purpose

BL brightness and VR volume OSDs (mirrored) sharing one slider. Maths and state are pure logic; painting is (manual).

## Requirements

### Requirement: Slider maths

The slider MUST convert value <-> position linearly over the track, clamp results to the range (volume 0..1, brightness 0..100), and apply the wheel step token per notch (up = +, down = -).

#### Scenario: Value to position (track 200 px, range 0..1)
| Value | Position |
|---|---|
| 0 | 0 |
| 0.5 | 100 |
| 1 | 200 |
| 1.3 | 200 |

#### Scenario: Position to value (range 0..100, track 200 px)
| Position | Value |
|---|---|
| -10 | 0 |
| 50 | 25 |
| 250 | 100 |

#### Scenario: Wheel (step 0.05 volume)
| Value | Wheel | Result |
|---|---|---|
| 0.50 | +1 | 0.55 |
| 0.98 | +1 | 1 |
| 0.02 | -1 | 0 |

#### Scenario: Tap and drag
- GIVEN track 200 px, range 0..1
- WHEN the user taps at 150 px, then drags to -20 px
- THEN the value is 0.75, then 0

### Requirement: Reveal state machine

Each OSD MUST reveal on value or mute change, hide after `Timings.reveal`, and stay open while hovered or dragged, restarting the timeout on leave. New changes while visible MUST restart the timeout.

#### Scenario: Transition table
| State | Event | Next |
|---|---|---|
| hidden | value change | visible, timer start |
| visible | value change | visible, timer restart |
| visible | timeout | hidden |
| visible | hover enter | held, timer stop |
| held | hover leave | visible, timer restart |
| held | timeout | held |
| visible | drag start | held |

### Requirement: Startup gate

Changes within the startup-gate token period after load MUST NOT reveal an OSD. The initial value read MUST NOT count as a change.

#### Scenario: Gate table (gate 1000 ms)
| Time | Event | Reveals |
|---|---|---|
| 0 | initial value load | no |
| 500 | value change | no |
| 1200 | value change | yes |

### Requirement: Mute display

The volume OSD MUST show a dimmed track and muted icon while muted; right-click MUST toggle mute. Brightness right-click MUST do nothing. The OSD MUST be hidden when its service is unavailable.

#### Scenario: Mute table
| muted | Track | Icon |
|---|---|---|
| false | normal | volume icon |
| true | dimmed | muted icon |

#### Scenario: Unavailable
- GIVEN `Audio.available` false
- WHEN volume changes are signalled
- THEN the VR OSD stays hidden

### Requirement: Presentation (manual)

The slider MUST show the icon inside the round thumb and the numeric value. BL MUST sit between TL and centre, VR between centre and TR, with input masks covering only the visible shape.

#### Scenario: Layout (manual)
- GIVEN both OSDs revealed
- WHEN viewed
- THEN they mirror each other, with icon in the thumb and the value shown

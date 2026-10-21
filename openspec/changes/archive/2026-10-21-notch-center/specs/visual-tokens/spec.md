# Delta for Visual Tokens

## ADDED Requirements

### Requirement: Centre content tokens

`shell/config/` MUST add: battery thresholds low 20 and critical 10; a critical red colour; week-strip radius 3; battery layer extra width; expanded widths (full and clock-only); and every new UI string. Literals for these MUST NOT appear outside `shell/config/`.

#### Scenario: Threshold tokens
- GIVEN the config module
- WHEN `classify` receives the tokens
- THEN 19% unplugged is `low` and 20% is `none`

#### Scenario: Literal scan
- GIVEN the new idle and expanded QML files
- WHEN scanned for colour, duration, font or text literals
- THEN none are found

#### Scenario: Expanded within max
- GIVEN the expanded width tokens
- WHEN compared with `Layout.centerMaxWidth`
- THEN the clamped result never exceeds it

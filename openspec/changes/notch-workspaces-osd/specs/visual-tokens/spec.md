# Delta for Visual Tokens

## ADDED Requirements

### Requirement: Workspaces and OSD tokens

`shell/config/` MUST provide: workspace slot count (default = old `maxVisible`) and the workspace event debounce in `Limits`/`Timings`; the startup-gate timing in `Timings`; the OSD wheel step in `Limits`; the volume, muted-volume and brightness OSD icons and the active/empty symbols (`●`, `–`) in `Strings`; and every new user-visible string. `Timings.reveal` (existing) MUST drive both strips and OSDs. Literals for these MUST NOT appear outside `shell/config/`.

#### Scenario: Tokens resolve
- GIVEN the config module
- WHEN QML or logic tests read the new tokens
- THEN slot count, debounce, startup gate, wheel step, icons and symbols are defined

#### Scenario: Literal scan
- GIVEN the new workspaces and OSD QML files
- WHEN scanned for colour, duration, font or text literals
- THEN none are found

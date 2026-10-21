# 0002. Hybrid layout with pure logic modules

- Status: accepted
- Date: 2026-10-21

## Context

The old config mixed data, decisions and painting in QML, which made it hard to test and led to bugs (visibility flags, polling services). The notch has non-trivial rules: state priorities, notification queue, workspace symbols, calendar grid.

## Decision

Split `shell/` into `config/` (tokens), `services/` (data singletons), `logic/` (pure `.mjs`, no Quickshell/Qt imports), `components/` (reusable UI) and `notches/{center,workspaces,osd,controlcenter}/`. QML asks `logic/` and paints. One `qmldir` per QML folder. Tests live in `tests/` outside `shell/`.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Feature folders only (each notch owns its services and logic) | Locality | Services are shared across notches; logic untestable if inline | Duplicates services |
| Flat layout like the old config | Simple | Same problems as the old config | Rejected by experience |

## Consequences

- Positive: most rules are unit-testable with `node --test`; services are reusable across notches and monitors.
- Negative: an extra hop (QML -> logic) for simple cases; discipline needed to keep `logic/` pure.
- Follow-ups: lint `logic/` with deno; never import Qt/Quickshell there.

# 0003. Testing: node --test for logic, smoke run, manual UI

- Status: accepted
- Date: 2026-10-21

## Context

Strict TDD is required. Verified on the host: a `.mjs` file imported by QML (`import "x.mjs" as X`) works in Quickshell at runtime and the same file runs under `node --test`. `qmltestrunner` exits 1 silently with the offscreen platform.

## Decision

- Tests first for everything in `shell/logic/`, run with `node --test tests/`.
- Smoke test: `timeout 10 qs -p shell/shell.qml`; fail if the log contains `ERROR` or load errors.
- UI (animations, visuals, hover, masks) is verified manually with `qs -c notch`.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| qmltestrunner (Qt Quick Test) | Tests QML directly | Fails silently offscreen on this host | Unreliable |
| Jest / Vitest | Rich features | npm dependencies | Zero-dependency rule; node:test suffices |

## Consequences

- Positive: fast, dependency-free tests; same file in runtime and tests.
- Negative: QML wiring and visuals are not automatically tested; smoke needs a Wayland session (local only, not CI).
- Follow-ups: push as much behaviour as possible into `logic/`.

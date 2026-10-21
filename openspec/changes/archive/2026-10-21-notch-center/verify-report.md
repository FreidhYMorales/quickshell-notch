```yaml
schema: sdd.verify-result/v1
verdict: pass-with-warnings
blockers: 0
critical_findings: 0
requirements: 28/28
scenarios: 46/46
test_command: node --test tests/
test_exit_code: 0
build_command: NOTCH_SMOKE=1 timeout 120 make check
build_exit_code: 0
```

## Verification Report

**Change**: notch-center
**Version**: N/A
**Mode**: Strict TDD (runner `node --test tests/`)

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 43 |
| Tasks complete | 43 |
| Tasks incomplete | 0 |

PRs #10-#16 merged (main 0f3e19b).

### Build & Tests Execution
**Build / gate**: PASS. `make check` (qmlformat, qmllint, deno, node tests, smoke "config loaded"), exit 0.
**Tests**: 215 passed / 0 failed / 0 skipped (`node --test tests/`, exit 0).
**Coverage** (`--experimental-test-coverage`): all logic files 100% line/branch/function (battery, calendar, centerLayout, format, media, sideLayer, sysStats, visualizer); aggregate 100 / 99.42 / 100.

### TDD Compliance
| Check | Result | Details |
|---|---|---|
| TDD evidence reported | PASS | Per-PR tables in apply-progress.md |
| Logic tasks have tests | PASS | 8/8 logic modules have test files (battery, sysStats, calendar, media, centerLayout, format, sideLayer, visualizer) + surfaceLayout extension |
| RED confirmed | PASS | Files exist; RED reasons recorded (ERR_MODULE_NOT_FOUND etc.) |
| GREEN confirmed | PASS | All 215 pass now |
| Triangulation | PASS | Table-driven multi-case tests everywhere |
| Safety net | PASS | Recorded for modified files (PR 3, PR 4) |
| QML tasks | N/A | No logic; rules live in tested `.mjs`; covered by `make check` + scratch `qs -p` probes |

**Test layers**: Unit only (215 tests, node:test); no integration/E2E tooling exists. QML behaviour is covered by manual evidence (SUGGESTION, inherent to stack).
**Assertion quality**: no tautologies, ghost loops or type-only assertions found (grep + review of names). Table tests iterate non-empty fixed arrays.
**Linter/type**: qmllint (only pre-existing warnings in CenterSurface/Mpris), deno lint/fmt, qmlformat: clean.

### Spec Compliance Matrix
Legend: T = passing automated test; M-user = confirmed manually by the user; M-agent = scratch `qs -p` probe by the agent; S = smoke/static.

| Capability | Scenario | Evidence | Result |
|---|---|---|---|
| audio-visualizer | Valid frame | tests/visualizer.test.mjs parseFrame rows | COMPLIANT (T) |
| | Malformed frame (null, last frame kept) | parseFrame `1;x;3;`/negative -> null (T); keep-last in Cava.qml (static) | COMPLIANT (T + static) |
| | Rest (flat line) | barGeometry all-zero | COMPLIANT (T) |
| | Symmetry | barGeometry mirrored | COMPLIANT (T) |
| | Play then pause | M-user (pause flattens bars); M-agent (cava stops with player) | COMPLIANT (M) |
| | Smoke mode | `Cava.running = wanted && !Flags.smoke`; make smoke green | COMPLIANT (S) |
| | Colours | pickAccent (T); art colour picked `#e0402a` (M-agent); art/bars visual M-user; primary fallback not user-checked | PARTIAL (M) |
| | Docs | docs/development.md:27,34; AGENTS.md:47 | COMPLIANT |
| battery-service | No battery | fromUPower missing battery (T) | COMPLIANT (T) |
| | Plug-in edge | `edges` test (T); QML signal wiring static only | COMPLIANT (T) |
| | Boundary 19 vs 20 | classify spec table | COMPLIANT (T) |
| | Plug replaces low | classify test | COMPLIANT (T) |
| | Fires once | criticalStep | COMPLIANT (T) |
| | Re-arm on plug-in | criticalStep | COMPLIANT (T) |
| | Plugged never fires | criticalStep | COMPLIANT (T) |
| | Override | M-agent (7 scenarios) + M-user (charging, low) | COMPLIANT (M) |
| center-expanded-view | With player | M-user (browser, ncmpcpp) | COMPLIANT (M) |
| | No art | M-agent screenshot (glyph fallback) | COMPLIANT (M) |
| | Midnight rollover | calendar.test "midnight rollover recentres" (T); strip binds Time.dayOfMonth | COMPLIANT (T) |
| | No player | M-agent (300 px, clock only) | COMPLIANT (M) |
| | Narrow monitor | expandedWidth max=400/250 rows | COMPLIANT (T) |
| center-idle-view | Live content | M-user | COMPLIANT (M) |
| | Recording dot | M-agent (`Recorder.recording=true`, low + rec) | COMPLIANT (M) |
| | Charging | M-user | COMPLIANT (M) |
| | Plug replaces low | classify (T) + M-user layers | COMPLIANT (T + M) |
| | Clock stays put | centerLayout/sideLayer composition tests + M-agent offset 0 | COMPLIANT (T) |
| | Low beats media | sideLayer table (T) + M-user | COMPLIANT (T + M) |
| | Media beats charging | sideLayer table (T) | COMPLIANT (T) |
| | Pause releases layer | sideLayer pause test (T) | COMPLIANT (T) |
| | Playing | M-user | COMPLIANT (M) |
| | No art (media layer) | M-agent glyph fallback; not user-checked | COMPLIANT (M) |
| | Rounding (formatPercent) | format.test formatPercent rows | COMPLIANT (T) |
| media-service | Player appears | M-user (players started live) | COMPLIANT (M) |
| | Player quits | M-user/M-agent (quit player) | COMPLIANT (M) |
| | Prefers playing | selectPlayer rows | COMPLIANT (T) |
| | Switch when playback moves | media.test switch | COMPLIANT (T) |
| | Play/pause | M-user (play/pause); "only selected player" static | COMPLIANT (M) |
| shell-surfaces | Idle | M-user (all monitors live) | COMPLIANT (M) |
| | Smoke | make check smoke green | COMPLIANT (S) |
| system-status-services | Values in range (SysInfo) | sysStats tests (T); M-agent cpu=2 ram=16; M-user live row | COMPLIANT (T + M) |
| | Midnight (`msUntilMidnight` = 30000) | Function does not exist; replaced by dayKey change signal (Time.qml:25); behaviour covered by calendar dayKey test | PARTIAL (design drift) |
| | Locale independent (formatDate) | format.test shortDate | COMPLIANT (T) |
| | Toggle (Recorder) | M-agent (setRecording true shows dot); false-after-true not explicitly shown | PARTIAL (M) |
| visual-tokens | Threshold tokens | classify limits from caller (T); Limits.qml 20/10 | COMPLIANT (T) |
| | Literal scan | rg for colour/timing literals outside shell/config: none | COMPLIANT (S) |
| | Expanded within max | expandedWidth narrow rows | COMPLIANT (T) |

**Compliance summary**: 46/46 scenarios have evidence; 42 fully compliant, 4 partial (all non-blocking, see warnings). Requirements: 28/28 implemented.

### Correctness (Static Evidence)
All 28 requirements are implemented; names follow the reconciled design (idleWidth/idleBase/sideExtent, sideLayer, parseFrame, plugged via UPower.onBattery, extra `plugged` layer, content-sized idle notch, 24-hour clock). Files present: services (Battery, Time, Mpris, SysInfo, Recorder, Cava), components (ArcMeter, ArtThumb, Visualizer, NotchZone), notches/center (Idle, Expanded, Media, ClockCard, Store, Surface).

### Coherence (Design)
| Decision | Followed? | Notes |
|---|---|---|
| Pure logic in shell/logic, QML thin | Yes | 8 modules at 100% coverage |
| Single shape item = mask + NotchZone | Yes | CenterSurface |
| No polling for battery/mpris | Yes | signal-driven |
| Cava lifecycle (config rewrite, retries, smoke guard) | Yes | Cava.qml; retry handler on onRunningChanged |
| Tokens only outside config | Yes | literal scan clean |
| Deviations recorded | Yes | `Time.dayOfMonth`, `CenterIdle.batteryLayer`, content-sized idle width |

### Issues Found
**CRITICAL**: None.

**WARNING**:
1. Spec scenario "Midnight" (`msUntilMidnight` = 30000) has no matching function or test; implementation uses a `dayKey` change signal. Behaviour is tested via `dayKey`/rollover tests, but the spec text is stale. Fix the spec at archive (or add a tiny pure function).
2. Stale spec wording to reconcile at archive: idleLayout/selectIdleLayer/parseCavaFrame names; barGeometry `{top,bottom}`/`minBar` vs implemented `barGeometry(levels, {height, barWidth, gap, minHeight})`; "line-power device" vs `onBattery`; battery-service classify layer list lacks `plugged`; Layout `batterySide` removal; idle width spec (`idleLayout` symmetric `base + 2*extra`) vs content-driven `idleBase`/`sideExtent`.
3. Known follow-up: critical event is lost if the shell starts at <= 10% (store Connections attach after first refresh); deferred to notch-notifications.
4. Manual-only evidence for QML scenarios (no QML test harness): see remaining manual list.

**SUGGESTION**:
1. Unread dot source is not wired (explicitly out of scope).
2. Recorder is minimal (setRecording); full port deferred to notch-control-center.
3. Consider a QML-level test harness later; all layers are unit-only.

### Remaining manual checks (not yet confirmed by the user)
- Bar colour fallback to matugen `primary` for a track with no art, and https art (Spotify) fallback.
- Media layer glyph with no art (idle) and expanded no-art glyph on real hardware.
- `pkill cava` restart then give-up after 3 (stub-covered by agent only), cava missing from PATH.
- Cava CPU below ~2% of a core.
- Rec dot with a real recorder (only forced via `setRecording`), width unchanged.
- Midnight rollover live; narrow-monitor clamp live.
- Plug-in/unplug edge on the real charger and `plugged` (80% limit) layer visually.

### Verdict
PASS WITH WARNINGS. Gates green (215/215, make check exit 0), 43/43 tasks done, no CRITICAL; warnings are spec-text drift to reconcile at archive.

## Resolutions (2026-10-21)

- W1 and W2: reconcile the main specs at archive (design/implementation wins): `msUntilMidnight` scenario replaced by the `dayKey`-driven rollover actually implemented; names `idleWidth`/`idleBase`/`sideExtent`, `sideLayer`, `parseFrame`, `barGeometry` shape; `plugged` derived from `UPower.onBattery` + state and present in the `classify` layer list; content-driven idle width.
- W3 deferred to `notch-notifications` (critical event at shell start <= 10%).
- W4 accepted per ADR 0003.
- Remaining manual checks are opportunistic (plugged layer at the 80% limit, no-art and https-art colour fallback, midnight rollover, real recorder dot in notch-control-center).

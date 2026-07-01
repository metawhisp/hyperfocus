# 06 — Testing & QA Specification

> Derived from `specs/BRIEF.md` (product truth) and `specs/00-canon.md` (technical truth).
> On any conflict, `00-canon.md` wins on technical details. All identifiers, thresholds
> (7 s warning / 15 s away / 3 s recovery), strings, and paths below are canon — do not rename.
> Implementing agents follow TDD per `CLAUDE.md`: write the failing test from the catalog in §4
> BEFORE the code that makes it pass.

---

## 1. Test pyramid

### 1.1 Unit tested (XCTest, target `HyperfocusTests`, canon §2)

| Test file | Subject | What is covered |
|---|---|---|
| `HyperfocusTests/SessionReducerTests.swift` | `SessionReducer.reduce(_:_:)` — pure, synchronous, no AppKit/AVFoundation/filesystem (canon §5) | Every transition T1–T18, counter arithmetic, debounce boundaries, no-camera behavior, unhandled-event no-ops |
| `HyperfocusTests/SessionTimerTests.swift` | `SessionTimer` | Monotonic-clock deltas, 1 Hz tick contract, sleep-gap delta pass-through, start/stop |
| `HyperfocusTests/SessionStoreTests.swift` | `SessionStore` | JSON roundtrip, corrupt-file recovery, `clear()`, directory creation (injectable directory URL per canon §7) |
| `HyperfocusTests/OrbPositionStoreTests.swift` | `OrbPositionStore` | Position persistence roundtrip, clamping to visible bounds, malformed-value fallback |

The reducer is the **primary TDD surface** (canon §5). It owns all timing thresholds and counters, so the entire presence/away/recovery mechanic is verifiable headlessly.

### 1.2 Deliberately NOT unit tested — and its replacement coverage

| Not unit tested | Why | Covered by |
|---|---|---|
| AppKit windows (`FocusOrbWindowController`, `AuraWindowController`, `OverlayWindow`, `KeyablePanel`, countdown window) | Window level/focus/click-through behavior is not meaningfully assertable in XCTest | Manual QA script §5 (steps 2–5, 9–13) |
| `CameraPresenceService`, `CameraPermissionService` (AVFoundation + Vision) | Requires real hardware + TCC permission state | Manual QA §5 (steps 8, 10–13, 19–21) + debug simulation §6 via `SimulatedPresenceService` |
| `VoicePromptService`, `AlarmService` (audio engines) | Audible output; no assertable API surface worth mocking | Manual QA §5 (steps 8, 12, 13) — listen checks |
| SwiftUI view rendering (all of `UI/`, `FocusOrbView`, `AuraFrameView`) | Pixel output; snapshot tooling is out of scope (no dependencies allowed, canon §1) | Manual QA §5 + debug simulation §6 |
| `SessionCoordinator` | Thin, mostly untested glue by design (canon §5) | Debug simulation §6 exercises every effect end-to-end |

The rule: **all logic lives in the reducer/timer/stores where it is unit tested; everything not unit tested must be reachable through §5 or §6 scripts.** If a bug is found in untested glue, first ask whether the logic belongs in the reducer (see `CLAUDE.md`: fix at the owner layer).

---

## 2. How to run

```bash
brew install xcodegen        # once
cd <repo root>
xcodegen generate            # regenerates Hyperfocus.xcodeproj from project.yml
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus test
```

From Xcode: `open Hyperfocus.xcodeproj`, then Cmd-U (test) / Cmd-R (run). The `Hyperfocus` scheme includes the `HyperfocusTests` unit target. Unit tests must pass with no camera attached, no camera permission, and no network — they touch only pure code and temp directories.

CI note: `xcodebuild … test` is headless-safe for the unit suite. The debug-simulation script (§6) removes the camera dependency but still needs a logged-in GUI session (it drives real windows); it is for camera-less/CI-machine *interactive* verification, not display-less runners.

---

## 3. Naming convention

- Transition tests: `test_T<n>_<fromState>To<toState>_<expectation>`
  e.g. `test_T8_warningToAway_pausesTimerStartsAlarmIncrementsBreakCount`
- Everything else: `test_<unit>_<behavior>`
  e.g. `test_timer_sleepGapEmitsSingleLargeDelta`, `test_store_corruptFileRecoversAsEmpty`
- One assertion theme per test. Guard/rejection cases use the same `T<n>` prefix with `_rejects…` / `_staysIn…` suffixes.
- **This §4 catalog is the authoritative source for unit-test names (D5).** Test names appearing in specs/03, specs/04, and specs/05 are informal references; on any mismatch, this catalog wins.

Tick ordering rule used by all tests (derived from canon §4 condition phrasing `.tick while ctx.faceMissingSeconds ≥ threshold`): **a tick first accrues time in the current state, then evaluates threshold transitions.** The tick that crosses a threshold both accrues and transitions.

---

## 4. Unit test catalog

### 4.1 SessionReducerTests — transition table (canon §4)

| Test | Expected outcome |
|---|---|
| `test_T1_idleToPreparing_emitsShowStartCard` | state `preparing`; effects `[.showStartCard]` |
| `test_T2_preparingToIdle_onCancel_emitsHideStartCard` | state `idle`; effects `[.hideStartCard]` |
| `test_T3_preparingToCountdown_emitsCountdownVoiceAndCameraWarmup` | state `countdown`; effects contain `.hideStartCard`, `.showCountdown`, `.playVoice(.countdown)`, `.startCameraWarmup` |
| `test_T3_preparing_rejectsEmptyMission_staysInPreparing` | `.enterHyperfocus` with empty/whitespace mission → state unchanged, no effects |
| `test_T4_countdownToActive_startsTimerAuraPresence` | state `active`; effects contain `.dismissCountdown`, `.setAura(.green)`, `.startTimer`, `.startPresenceDetection` |
| `test_T5_countdownToIdle_onExit_abortsWithoutSaving` | state `idle`; effects contain `.dismissCountdown`, `.stopCamera`; NO `.saveSession` |
| `test_T6_activeToWarning_atThreshold_setsYellowAura` | `faceMissingSeconds ≥ 7` on tick → state `warning`; effects `[.setAura(.yellow)]` |
| `test_T7_warningToActive_onFacePresent_noRecoveryDelay` | state `active` immediately; effects `[.setAura(.green)]`; `faceMissingSeconds == 0` |
| `test_T8_warningToAway_pausesTimerStartsAlarmIncrementsBreakCount` | `faceMissingSeconds ≥ 15` on tick → state `away`; effects contain `.setAura(.red)`, `.pauseTimer`, `.startAlarm`, `.playVoice(.away)`, `.showAwayCard`; `breakCount == 1`; `currentStreakSeconds == 0` |
| `test_T9_activeToAway_onSimulateAway_sameEffectsAsT8` | direct away (debug fast-forward) from `active` → identical state/effects/counters as T8 |
| `test_T10_awayToRecovering_onFacePresent_alarmKeepsPlaying` | state `recovering`; effects `[.showRecoveryCountdown]`; NO `.stopAlarm` |
| `test_T11_recoveringToAway_onFaceLost_hidesRecoveryCountdown` | state `away`; effects `[.hideRecoveryCountdown]`; NO `.stopAlarm`; `recoveryElapsed` reset to 0 |
| `test_T12_recoveringToActive_afterRecoverySeconds_resumesEverything` | `recoveryElapsed ≥ 3` with face present on tick → state `active`; effects contain `.stopAlarm`, `.hideAwayCard`, `.hideRecoveryCountdown`, `.setAura(.green)`, `.resumeTimer`, `.playVoice(.restored)` |
| `test_T13_activeToManualPaused_pausesTimerDimsAura` | state `manualPaused`; effects `[.pauseTimer, .setAura(.dimmed)]`; `breakCount` unchanged; `currentStreakSeconds == 0` |
| `test_T14_manualPausedToActive_onResume_resumesTimerGreenAura` | state `active`; effects `[.resumeTimer, .setAura(.green)]` |
| `test_T15_activeToCompleted_atZeroRemaining_stopsAllPlaysCompleteShowsCompletion` | tick with `remainingFocusTime == 0` → state `completed`; effects contain `.stopTimer`, `.stopCamera`, `.stopAlarm`, `.setAura(.flashThenHide)`, `.playVoice(.complete)`, `.showCompletion` |
| `test_T15_warningToCompleted_atZeroRemaining_sameAsFromActive` | same outcome when the final tick lands in `warning` |
| `test_T16_activeToExitedToIdle_savesExitedSession` | `.userExited` from `active` → effects contain `.stopTimer`, `.stopCamera`, `.stopAlarm`, `.setAura(.hidden)`, `.hideAwayCard`, `.saveSession(status: .exited)`; final state `idle` (T18 immediate) |
| `test_T16_fromWarningAwayRecoveringManualPaused_userExited_allReachIdle` | `.userExited` from each of `warning`, `away`, `recovering`, `manualPaused` → same T16 effect set, final state `idle` |
| `test_T17_completedToIdle_onResultSaved_savesSessionAndFlashesOrb` | `.resultSaved(.done, nextAction:)` → state `idle`; effects contain `.saveSession(.done)`, `.hideCompletion`, `.orbFlash`; `nextAction` captured on the persisted model |
| `test_reducer_unhandledEvent_isNoOp` | e.g. `.tick` in `idle`, `.userResumed` in `active`, `.orbClicked` in `countdown` → state and context unchanged, effects `[]` |

### 4.2 SessionReducerTests — counter arithmetic (canon §4 rules; worked example per specs/03 §4)

Worked example, driven entirely through `reduce` with 1 Hz `.tick(deltaSeconds: 1.0)`:
config `plannedDurationSeconds = 300`, camera on. Timeline and checkpoint assertions:

| Phase | Events | Checkpoint (asserted after phase) |
|---|---|---|
| A | active for 60 ticks | `remaining 240`, `activeFocus 60`, `currentStreak 60`, `longestStreak 60`, `paused 0`, `breakCount 0` |
| B | `.facePresenceChanged(false)`, then 15 ticks (warning entered at missing ≥ 7, away at ≥ 15) | on entering `away`: `remaining 225`, `activeFocus 75` (warning ticks still count as focus), `longestStreak 75`, `currentStreak 0` (reset), `breakCount 1`, `paused 0` |
| C | 20 ticks in `away`, then `.facePresenceChanged(true)`, then 3 ticks in `recovering` | after T12: `paused 23` (away + recovering both accrue paused), `remaining 225`, `activeFocus 75` |
| D | 30 ticks in `active` | `activeFocus 105`, `remaining 195`, `currentStreak 30`, `longestStreak 75` |
| E | `.userPaused`, 10 ticks, `.userResumed` | `paused 33`, `currentStreak 0`, `breakCount` still 1 (manual pause never increments it) |
| F | 195 ticks in `active` → T15 fires | final: `activeFocus 300`, `remaining 0`, `paused 33`, `breakCount 1`, `longestStreak 195` (final streak overtakes 75); invariant `activeFocus + paused == total elapsed 333` |

Individual counter tests (each standalone, not only via the worked example):

| Test | Expected outcome |
|---|---|
| `test_reducer_warningTicks_stillDecrementRemainingAndAccrueFocus` | in `warning`, each tick: `remaining -1`, `activeFocus +1`, `currentStreak +1` |
| `test_reducer_awayRecoveringManualPausedTicks_accruePausedOnly` | in each of the three states, tick: `paused +1`, `remaining`/`activeFocus` unchanged |
| `test_reducer_currentStreak_notResetOnWarning` | active→warning→active keeps the streak accumulating (reset only on `away`/`manualPaused` entry) |
| `test_reducer_longestStreak_updatedEveryTick` | `longestStreak == max(longestStreak, currentStreak)` holds after every tick |
| `test_reducer_breakCount_incrementsOncePerAwayEntry` | away→recovering→away again (T11) → `breakCount 2`; staying in away for N ticks → still 1 |
| `test_reducer_sleepGap_excessCountsAsPaused` | tick `deltaSeconds: 60.0` in `active` → `remaining -1` (clamped), `activeFocus +1`, `paused +59` |
| `test_reducer_smallDeltaOverrun_clampedWithoutPausedCredit` | tick `deltaSeconds: 3.0` (≤ 5 s stall) in `active` → `remaining -1`, `paused` unchanged (canon: excess goes to paused only when delta > 5 s) |
| `test_reducer_noCameraSession_neverEntersWarningOrAway` | config `cameraEnabled == false`: no presence events fire; 100 ticks → still `active`; only `.userPaused`/`.userExited` change state |
| `test_reducer_facePresentRaw_resetsFaceMissingSeconds` | accumulate missing 6 s, `.facePresenceChanged(true)`, missing again 6 s → still `active` (counter restarted, never reached 7) |

### 4.3 SessionReducerTests — debounce boundary cases

Feed face-missing ticks summing to the exact boundary (fractional deltas allowed; accrue-then-evaluate per §3):

| Test | Expected outcome |
|---|---|
| `test_reducer_faceMissing6_9s_staysActive` | `faceMissingSeconds == 6.9` → state `active`, no aura change |
| `test_T6_activeToWarning_atExactly7_0s` | crossing to `7.0` → state `warning`, `.setAura(.yellow)` |
| `test_reducer_faceMissing14_9s_staysWarning` | `faceMissingSeconds == 14.9` → still `warning`, timer still running |
| `test_T8_warningToAway_atExactly15_0s` | crossing to `15.0` → state `away`, full T8 effect set |
| `test_reducer_recoveryInterruptedAt2_9s_returnsToAway` | in `recovering` with `recoveryElapsed == 2.9`, `.facePresenceChanged(false)` → `away` (T11), alarm never stopped, next `.facePresenceChanged(true)` restarts recovery from `0` |
| `test_reducer_recoveryCompletes_atExactly3_0s` | `recoveryElapsed` crossing to `3.0` with face present → `active` (T12) |
| `test_reducer_thresholdsReadFromContext_notHardcoded` | ctx configured with `warning 5 / away 10 / recovery 2` (user-tunable per canon §8) → transitions honor those values |

### 4.4 SessionTimerTests

`SessionTimer` must take an injectable monotonic now-source (`ContinuousClock` / `CACurrentMediaTime()` in production, canon §4).

| Test | Expected outcome |
|---|---|
| `test_timer_deltaComputedFromMonotonicClock` | advance injected clock by 1.0 between ticks → emitted `deltaSeconds == 1.0` (wall-clock changes irrelevant/ignored) |
| `test_timer_sleepGapEmitsSingleLargeDelta` | advance injected clock by 60.0 → next tick carries `deltaSeconds == 60.0` (clamping is the reducer's job, not the timer's) |
| `test_timer_neverEmitsNegativeOrZeroDeltaAsNegative` | non-monotonic glitch (clock returns same value) → `deltaSeconds ≥ 0` |
| `test_timer_stopCeasesTicks` | after `stop()`, no further tick callbacks fire |
| `test_timer_restartResetsDeltaBaseline` | stop, advance clock 100 s, start → first tick delta measured from restart, not from old baseline |

### 4.5 SessionStoreTests

All tests use an injected temp directory (canon §7), never the real Application Support path.

| Test | Expected outcome |
|---|---|
| `test_store_appendThenAll_roundtripsAllFields` | append a fully-populated `Session` (incl. `successCondition`, `nextAction`, `endedAt`, `completionStatus: .partial`, `intensity: .cinematic`) → fresh `SessionStore` on the same directory returns an equal value |
| `test_store_optionalFieldsNil_roundtrip` | `successCondition == nil`, `nextAction == nil`, `endedAt == nil` survive encode/decode |
| `test_store_corruptFileRecoversAsEmpty` | write `not-json{{{` to `sessions.json` → `all()` returns `[]` without throwing/crashing; subsequent `append` rewrites a valid file containing exactly 1 session |
| `test_store_missingDirectoryIsCreated` | point store at a non-existent nested directory → `append` creates it and writes `sessions.json` |
| `test_store_clear_emptiesListAndFile` | after 3 appends, `clear()` → `all() == []` and the on-disk JSON decodes to an empty array |
| `test_store_appendPreservesOrder` | 3 appends → `all()` returns them in insertion order |

### 4.6 OrbPositionStoreTests

Visible bounds injected as a `CGRect` (no `NSScreen` in unit tests). Key: `hf.orbPosition`, String JSON `{x,y}` (canon §8).

| Test | Expected outcome |
|---|---|
| `test_orbStore_saveThenLoad_roundtrips` | saved point loads back equal |
| `test_orbStore_clampsOffscreenPosition` | stored `{x: 10000, y: 10000}` with visible bounds 1440×900 → loaded position clamped inside the bounds (orb fully visible) |
| `test_orbStore_clampsNegativePosition` | stored `{x: -500, y: -500}` → clamped inside bounds |
| `test_orbStore_malformedValueFallsBackToDefault` | key contains `garbage` → default position: bottom-right, 8 pt margin (canon §8) |
| `test_orbStore_missingKeyFallsBackToDefault` | no stored value → same default |

### 4.7 SessionReducerTests — camera degradation (D1)

`.cameraStateChanged(.unavailable)` — same outcome for `.disabled` and `.notAuthorized` — arriving mid-session must never leave the session stuck with a looping alarm:

| Test | Expected outcome |
|---|---|
| `test_cameraLoss_activeStaysActiveTimerRuns` | camera loss in `active` → state stays `active`; timer keeps running (`remainingFocusTime` still decrements on ticks); presence-driven transitions disabled (no warning/away thereafter); HUD shows `Camera off` |
| `test_cameraLoss_warningReturnsToActive` | camera loss in `warning` → state `active` applying T7's effect list (`.setAura(.green)`); `faceMissingSeconds == 0` |
| `test_cameraLoss_awayEntersRecovering` | camera loss in `away` → treated exactly as `.facePresenceChanged(true)`: state `recovering` (T10, `.showRecoveryCountdown`, alarm keeps playing); after `recoverySeconds` of ticks → `active` (T12: alarm stops, timer resumes). In `recovering`, camera loss is likewise treated as face present (recovery continues) |

---

## 5. Manual QA script (real camera; maps to the 30 BRIEF acceptance criteria)

Precondition for a clean first run: `tccutil reset Camera com.hyperfocus.app`, delete the sandbox container data (`~/Library/Containers/com.hyperfocus.app/`), quit the app.

| # | Step | Verifies AC |
|---|---|---|
| 1 | `xcodegen generate`, build & run from Xcode. Onboarding appears (5 screens ending `Start using Hyperfocus`); complete it | 1 |
| 2 | Small glass Focus Orb visible on screen, floating above other windows | 2 |
| 3 | Drag the orb around; release near an edge → it snaps to an 8 pt margin | 3 |
| 4 | Quit app (menu bar extra → Quit), relaunch → orb reappears at the same position | 4 |
| 5 | Click the orb → `Prepare Hyperfocus` card opens (subtitle `One task. One session.`) | 5 |
| 6 | Leave Mission empty → `Enter Hyperfocus` is disabled/refuses to start | 8 |
| 7 | Type a mission; verify typing works (KeyablePanel focus); pick the `5` minute preset; pick intensity | 6, 7 |
| 8 | Click `Enter Hyperfocus` → macOS camera permission dialog appears (first run); grant. Fullscreen countdown: screen darkens, `ENTER HYPERFOCUS MODE` → `3` → `2` → `1` → `FOCUS`, voice speaks `Enter Hyperfocus Mode. Three. Two. One. Focus.` | 9, 10, 11, 14 |
| 9 | Countdown dismisses → thin green aura on all 4 screen edges; HUD shows mission + remaining time counting down | 12, 13 |
| 10 | Sit normally in frame ≥ 30 s → HUD status `Present`, timer keeps decrementing | 15 |
| 11 | Leave the frame (or fully cover the camera); start a stopwatch. At ~7 s the aura turns yellow/orange; timer still runs | 16 |
| 12 | Stay away. At ~15 s: aura turns red, HUD time freezes (timer paused), continuous brown-noise alarm starts, voice says `Session paused. Return to Hyperfocus or exit.`, glass card `Session paused` with `Return` / `Exit Session` appears | 17, 18, 19, 20, 21 |
| 13 | Return to the frame and stay: recovery countdown `3` → `2` → `1` → `Back to focus`; after 3 s alarm stops, aura green again, timer resumes, voice says `Focus restored.` | 22, 23, 24 |
| 14 | Let the timer reach zero (use `Custom` = 1 min for a quick pass) → aura flashes green and fades, voice `Mission complete.`, completion card with Mission / Focus time / Paused time / Breaks / Longest streak; sanity-check Breaks == number of away episodes in this run | 25 |
| 15 | Answer `Did you complete the mission?` with `Done` (cover `Partial` / `Not done` on later passes); optionally fill `Next action` | 26 |
| 16 | Menu bar extra → History: the session is listed with correct date/mission/duration/status/breaks. Confirm on disk: `sessions.json` under the app's Application Support dir (inside the sandbox container) contains the session | 27 |
| 17 | The camera indicator (green dot in the menu bar) is OFF after the completion card is dismissed | 28 |
| 18 | Orb is back to its idle glass state (no green core) | 29 |
| 19 | Run the privacy checklist §7 in full | 30 |

Away-then-exit path (separate short pass): repeat steps 8–12, then click `Exit Session` on the away card → alarm stops, aura disappears, camera indicator off, orb idle; History shows the session with status `exited`.

No-camera fallback pass:
| # | Step | Verifies |
|---|---|---|
| 20 | `tccutil reset Camera com.hyperfocus.app`; start a session and DENY the permission dialog | permission-denied path of AC 14 |
| 21 | With `Allow sessions without camera` ON (default), the session still starts; HUD shows `Camera off`; no warning/away ever triggers; orb quick-actions `Pause` / `Exit Session` work (manual pause does not increment Breaks) | BRIEF no-camera fallback |
| 22 | With camera use enabled but unauthorized, HUD shows `Permission needed`; Settings → Camera shows permission status and the privacy copy verbatim | BRIEF camera states + privacy copy |

---

## 6. Debug-simulation QA script (no camera; canon §10)

Requires a `DEBUG` build. Menu bar extra → `Debug` submenu.

1. Toggle `Use Simulated Camera` ON (swaps `PresenceDetecting` to `SimulatedPresenceService` for the next session).
2. Start a session: mission `sim pass`, `Custom` duration 2 min, intensity `Cinematic`.
3. Countdown completes → **green** aura, timer running.
4. `Simulate: Face Present` → HUD `Present`; timer continues.
5. `Simulate: Face Missing` → after 7 s aura turns **yellow** (HUD `Looking for you`), timer still decrementing.
6. Wait until 15 s total missing (or use `Simulate: Jump to Away` to fast-forward `faceMissingSeconds` to the away threshold) → **red** aura, timer paused, **alarm** loop, away voice line, `Session paused` card.
7. `Simulate: Return` → recovery countdown `3`→`2`→`1`→`Back to focus`; after 3 s: alarm off, aura green, timer resumed, `Focus restored.`
8. Interrupted-recovery check: `Simulate: Face Missing` again, jump to away, `Simulate: Return`, then `Simulate: Face Missing` at ~2 s into recovery → drops back to away, alarm never stopped; `Simulate: Return` again completes recovery.
9. Let the timer run out → **completion** card; Breaks must equal the number of away entries (2 in this script), Paused time > 0, Longest streak plausible.
10. Save `Done` → History entry appears; orb idle.

This single pass exercises green → yellow → red → alarm → recovery → completion with zero camera involvement and is the standard smoke test on machines without a camera or permission.

---

## 7. Privacy verification checklist (AC 30 + canon §6 invariants)

### 7.1 Source greps — every command MUST print nothing

Run from the repo root against the app source tree:

```bash
grep -rn "AVCaptureMovieFileOutput" Hyperfocus/
grep -rn "AVAssetWriter" Hyperfocus/
grep -rn "AVCapturePhotoOutput" Hyperfocus/
grep -rn "URLSession" Hyperfocus/
grep -rn "import Network" Hyperfocus/
grep -rn "NWConnection" Hyperfocus/
grep -rn "CGImageDestination" Hyperfocus/
grep -rnE "(jpegData|pngData|tiffRepresentation)" Hyperfocus/
grep -rnE "CVPixelBuffer.*(write|Data\(|FileHandle)" Hyperfocus/
```

Any hit = release blocker. These enforce canon §6: no video recording, no frame persistence, no photo capture, no network calls anywhere in the app.

### 7.2 Entitlements & Info.plist review

```bash
grep -n "network" Hyperfocus/Resources/Hyperfocus.entitlements          # MUST print nothing (no network entitlements, canon §11)
grep -n "com.apple.security.device.camera" Hyperfocus/Resources/Hyperfocus.entitlements   # MUST be present, = true
grep -n "com.apple.security.app-sandbox" Hyperfocus/Resources/Hyperfocus.entitlements     # MUST be present, = true
```

`NSCameraUsageDescription` must match canon §11 verbatim: `Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally and never recorded or uploaded.`

### 7.3 Runtime checks

- After a real-camera session ends (completed AND exited paths): the menu-bar camera indicator (green dot) is off within a few seconds. If it stays on, `stopCamera` teardown (`stopRunning`, inputs/outputs removed — canon §6) is broken.
- File audit after a real-camera session: `find ~/Library/Containers/com.hyperfocus.app -type f` → app-written data is `sessions.json` (plus system-managed plist/caches); no `.mov`, `.mp4`, `.jpg`, `.png`, or frame dumps.

---

## 8. Performance sanity (targets, measured on the dev machine)

| Check | Method | Target |
|---|---|---|
| CPU during active session, user idle-watching (camera on, face present) | `top -l 12 -s 5 -pid $(pgrep -x Hyperfocus)`, average the samples | Low single-digit % (640×480 capture + 2 Hz Vision, canon §1). Sustained ≥ 10% = investigate before shipping |
| Timer drift over 25 min | Start a 25-min session, note wall-clock start; keep face present, no sleep, no manual pause. Compare completion moment to start + 25:00 | Within ±2 s (monotonic 1 Hz ticks, canon §4) |
| Memory across 3 consecutive sessions | Record Xcode memory gauge (or `footprint $(pgrep -x Hyperfocus)`) at idle before session 1 and at idle after session 3 (simulated camera OK; do one real-camera run too for capture-session leaks) | Returns to within a small constant of baseline; no monotonic growth per session. Run Instruments → Leaks once on the real-camera path |

These are sanity gates, not benchmarks: fail = profile and fix at the source (capture pipeline, timer, or aura redraw), not by tweaking targets.

---

## 9. Regression rule

At the **end of every phase** (Phases 1–10, BRIEF implementation plan), before marking the phase checklist closed in `PROGRESS.md`:

1. **Always (cheap, seconds):** full unit suite — `xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus test`. It contains the designated corner-case set, which must never be skipped or `XCTSkip`-ed:
   - boundary quartet: 6.9 s / 7.0 s / 14.9 s / 15.0 s (§4.3)
   - recovery interrupted at 2.9 s (§4.3)
   - sleep gap > 5 s → paused credit (§4.2)
   - no-camera session never enters warning/away (§4.2)
   - empty-mission guard (§4.1 T3 reject)
   - corrupt `sessions.json` recovery (§4.5)
   - off-screen orb clamp (§4.6)
2. **Always (cheap, seconds):** privacy grep block §7.1 + entitlements grep §7.2.
3. **From Phase 6 onward** (state machine + debug menu exist): one full debug-simulation pass (§6), ~4 minutes.
4. **Phase 7+ (camera phases) and any change touching `Camera/`:** manual steps 8–13 + runtime privacy checks §7.3 with the real camera.
5. **Phase 10 / before declaring the MVP done:** full manual QA §5 (all 22 steps + away-then-exit pass), performance sanity §8, and the complete §7 checklist.

Definition of Done for the whole project (per `CLAUDE.md` §4) includes: every table row in §4 implemented as a passing test, §5 executed end-to-end on real hardware, §7 fully clean.

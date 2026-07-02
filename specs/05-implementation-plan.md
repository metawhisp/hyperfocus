# 05 — Implementation Plan (Master)

> Execution plan for the Hyperfocus MVP. Built for AI coding agents running the Ralph loop
> defined in `CLAUDE.md`. Technical truth: `specs/00-canon.md` (canon). Product truth:
> `specs/BRIEF.md`. On any detail conflict, canon wins. All file paths, enum cases,
> thresholds, settings keys, and copy strings below are quoted from canon — never invent alternates.

---

## 1. How to work this plan

Every iteration follows the Ralph loop from `CLAUDE.md`:

1. **Start of iteration:** re-read `CLAUDE.md` and `PROGRESS.md` (kept at repo root; create it on the first iteration if missing). Re-read the current phase section of this plan.
2. **Take exactly ONE unchecked item** from the current phase checklist. One item = one iteration = one commit.
3. **TDD is mandatory for all reducer / timer / store work** (`SessionReducer`, `SessionTimer`, `SessionStore`, `OrbPositionStore` — canon §5 calls the reducer "the primary TDD surface"). Order: write the named failing test (red) → implement until green → refactor. No reducer/timer/store code without a failing test first.
4. **UI / window / service work** (views, window controllers, AVFoundation, audio) is verified by a green build plus the manual acceptance check listed on the item. Debug simulation (canon §10) is the manual-test harness once it exists (Phase 7, item 7.1).
5. **End of iteration:** run the full test suite and the phase's corner cases so far, tick the checkbox in this file, update `PROGRESS.md` (current phase, closed/open items, known bugs, next step), commit.
6. **Never proceed on a red build or red tests.** If the baseline is red, fixing it is the current iteration.

Verification commands (canon §1 — must stay true):

```bash
xcodegen generate            # regenerates Hyperfocus.xcodeproj from project.yml
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus -configuration Debug build
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus test
```

---

## 2. Phase 0 — Scaffold (ALREADY DONE — do not redo)

The scaffold exists before this plan runs: `project.yml`, the compilable skeleton of the canon §2
module map, and a green test baseline in `HyperfocusTests/`. Beyond stubs, the scaffold already
FULLY implements:

- the canonical enums/models (`SessionState`, `SessionEvent`, `SessionEffect`, `AuraState`,
  `CameraState`, `VoiceLine`, `CompletionStatus`, `Intensity`, `Session`, `SessionConfig`,
  `SessionContext`);
- `Constants.swift` (every canon literal: thresholds, keys, defaults, copy strings, tuning values);
- the service protocols (`PresenceDetecting`, `VoicePrompting`, `AlarmPlaying`) and `KeyablePanel`;
- `SettingsStore` with typed accessors and per-getter canon §8 defaults;
- `SessionStore` with JSON persistence (injectable directory URL, pretty-printed, `append`/`all`/`clear`);
- the `MenuBarExtra` skeleton in `HyperfocusApp.swift` with the populated `DEBUG` simulation submenu
  (placeholder no-op actions).

Everything else is a stub carrying an `// IMPLEMENT — see plan Phase N` marker — that marker is the
Phase-0 deliverable, not a TODO violation; remove each marker only when its plan item is closed.

**Agents start at Phase 1.** First action of Phase 1, item 1.1: run the three commands above
to confirm the baseline is green. If `project.yml` is missing or tests are red, STOP — record the
state in `PROGRESS.md` and report; do not scaffold ad hoc.

---

## 3. Master checklist

- [ ] Phase 1 — App shell
- [ ] Phase 2 — Focus Orb
- [ ] Phase 3 — Start card
- [ ] Phase 4 — Countdown
- [ ] Phase 5 — Aura
- [ ] Phase 6 — Timer engine
- [ ] Phase 7 — Camera presence
- [ ] Phase 8 — Away mode
- [ ] Phase 9 — Completion
- [ ] Phase 10 — Polish

---

## 4. Phases

Item format — **Files:** exact canon §2 paths; **RED:** the failing test(s) to write first
(reducer tests live in `HyperfocusTests/SessionReducerTests.swift` unless stated);
**Accept:** the check that closes the item.

### Phase 1 — App shell

**Goal:** menu-bar-only app boots with `AppState`/coordinator wiring and typed settings.
**Definition of Done:** app launches with no Dock icon (`LSUIElement = true`), `MenuBarExtra` shows the specs/01 §11 items (Show Focus Orb [conditional] / Settings… / Session History… / Debug [DEBUG only] / Quit Hyperfocus), `SettingsStore` exposes every canon §8 key with the canon default, build + tests green.
**Depends on:** Phase 0 scaffold only.

- [ ] **1.1 Baseline verify + app entry**
  - Files: `Hyperfocus/App/HyperfocusApp.swift`, `Hyperfocus/App/AppDelegate.swift`
  - Run canon build/test commands first; wire `@main` with `MenuBarExtra` + `NSApplicationDelegateAdaptor`.
  - Accept: app runs from Xcode, menu bar icon present, no Dock icon.
- [ ] **1.2 AppState + coordinator skeleton**
  - Files: `Hyperfocus/App/AppState.swift`, `Hyperfocus/App/SessionCoordinator.swift`
  - `AppState` (ObservableObject root) owns coordinator + protocol-typed services; all flow is `event -> reducer -> effects -> coordinator` (canon §2 rule). UI never talks to services directly.
  - Accept: build green; an injected `SessionEvent` reaches `SessionReducer.reduce` and returned effects reach the coordinator (log-level verification acceptable here).
- [ ] **1.3 SettingsStore + Constants**
  - Files: `Hyperfocus/Utilities/SettingsStore.swift`, `Hyperfocus/Utilities/Constants.swift`
  - Typed accessors for every `hf.*` key in canon §8; every literal (thresholds 7/15/3, orb size 18–24, aura 120 pt, snap 32 pt/8 pt, etc.) lives in `Constants.swift`.
  - Note: implementation pre-exists from Phase 0 — write the catalog tests from specs/06 §4 to verify it (they may pass immediately); do not re-stub or rewrite working code. The red-first rule applies only to code that does not exist yet.
  - Accept: build green; a debug dump of defaults matches the §8 table exactly.
- [ ] **1.4 Menu bar menu**
  - Files: `Hyperfocus/App/HyperfocusApp.swift`
  - Items exactly per specs/01 §11 (no `Start Session` item): `Show Focus Orb` (present only while the orb is hidden), `Settings…`, `Session History…`, `Debug` submenu wrapped in `#if DEBUG` (canon §10 items; wired in 7.1), `Quit Hyperfocus` (dispatches `.userExited` first if a session is running).
  - Note: implementation pre-exists from Phase 0 — write the catalog tests from specs/06 §4 to verify it (they may pass immediately); do not re-stub or rewrite working code. The red-first rule applies only to code that does not exist yet.
  - Accept: manual click-through; Quit terminates cleanly.

**Corner cases (end of phase):** relaunch works repeatedly; no Dock icon ever appears; first run with zero stored settings uses §8 defaults.

### Phase 2 — Focus Orb

**Goal:** draggable, edge-snapping, position-persisting glass orb, always on top.
**Definition of Done:** orb visible on launch on all Spaces, drag vs click disambiguated, snaps to edges, position survives relaunch and screen changes, `xcodebuild test` green.
**Depends on:** Phase 1 (AppState, SettingsStore).

- [x] **2.1 OrbPositionStore (TDD)**
  - Files: `Hyperfocus/Orb/OrbPositionStore.swift`, `HyperfocusTests/OrbPositionStoreTests.swift`
  - RED: `test_positionRoundTripsThroughDefaults`, `test_defaultPositionIsBottomRightWith8ptMargin`, `test_positionClampsIntoVisibleBounds` (JSON `{x,y}` under `hf.orbPosition`; injectable defaults + bounds).
  - Accept: tests green.
- [ ] **2.2 Orb window**
  - Files: `Hyperfocus/Utilities/KeyablePanel.swift`, `Hyperfocus/Orb/FocusOrbWindowController.swift`
  - `KeyablePanel` overrides `canBecomeKey = true`; styleMask `[.borderless, .nonactivatingPanel]`, level `.statusBar`, collectionBehavior `[.canJoinAllSpaces, .fullScreenAuxiliary]`, `isOpaque = false`, `backgroundColor = .clear` (canon §3).
  - Accept: build green; orb floats above normal windows on every Space without stealing focus.
- [ ] **2.3 Orb visuals**
  - Files: `Hyperfocus/Orb/FocusOrbView.swift`
  - Glass circle sized by `hf.orbSize` / `hf.orbOpacity`; visual states per BRIEF: idle glass, ready green pulse, active green core, warning yellow/orange pulse, away red core, completed green flash.
  - Accept: build green; each state verifiable by temporarily forcing it (remove the override before commit).
- [ ] **2.4 Drag, click, edge snap**
  - Files: `Hyperfocus/Orb/FocusOrbWindowController.swift`
  - NSEvent mouse tracking moves the panel frame (NOT `isMovableByWindowBackground` — it breaks click detection); click = mouseUp with < 4 pt total movement and < 0.3 s; snap when orb center is within 32 pt of an edge → animate to 8 pt margin (canon §3.4–3.5).
  - Accept: manual — drag works, click fires (log), snap animates to the correct edge.
- [ ] **2.5 Persist + clamp on screen change**
  - Files: `Hyperfocus/Orb/OrbPositionStore.swift`, `Hyperfocus/Utilities/ScreenManager.swift`, `Hyperfocus/App/AppDelegate.swift`
  - Save position on drag end; on `NSApplication.didChangeScreenParametersNotification` clamp into `NSScreen.main.visibleFrame` (canon §3.6).
  - Accept: relaunch restores position; changing display resolution pulls the orb back on-screen.

**Corner cases:** drag into a corner snaps to the nearest edge; click-vs-drag boundary (3 pt move = click, 5 pt = drag); stale off-screen saved position gets clamped; orb never becomes key unless clicked.

### Phase 3 — Start card

**Goal:** "Prepare Hyperfocus" card collects `SessionConfig` with validation and drives T1–T3.
**Definition of Done:** T1–T3 reducer tests green; card opens on orb click, cancel returns to idle, `Enter Hyperfocus` fires only with a non-empty mission.
**Depends on:** Phase 2 (orb click), Phase 1 (coordinator).

- [x] **3.1 T1 (TDD)**
  - Files: `Hyperfocus/Session/SessionReducer.swift`, `HyperfocusTests/SessionReducerTests.swift`
  - RED: `test_T1_idle_orbClicked_toPreparing_emitsShowStartCard`
  - Accept: test green.
- [x] **3.2 T2 (TDD)**
  - Files: same as 3.1
  - RED: `test_T2_preparing_cancelPreparing_toIdle_emitsHideStartCard`
  - Accept: test green.
- [x] **3.3 T3 + mission validation (TDD)**
  - Files: same as 3.1, plus `Hyperfocus/Session/SessionConfig.swift`
  - RED: `test_T3_preparing_enterHyperfocus_toCountdown_emitsHideStartCard_showCountdown_playVoiceCountdown_startCameraWarmup`, `test_T3_emptyMission_staysPreparing_noEffects` (whitespace-only mission counts as empty).
  - Accept: tests green.
- [ ] **3.4 Start card UI**
  - Files: `Hyperfocus/UI/StartSessionView.swift`, `Hyperfocus/UI/GlassCard.swift`
  - Exact canon §9 copy: title `Prepare Hyperfocus`, subtitle `One task. One session.`, mission placeholder `What are you doing in this session?`, success placeholder `This session is successful if…`, presets `5`/`15`/`25`/`45` minutes + `Custom` (1–180), intensity `calm`/`strict`/`cinematic`, primary CTA `Enter Hyperfocus`, secondary `Cancel`. CTA disabled while mission is empty. Defaults from `hf.defaultDurationMinutes` (25) and `hf.defaultIntensity` (`cinematic`).
  - Accept: build green; visual check against §9, string for string.
- [ ] **3.5 Present card next to orb**
  - Files: `Hyperfocus/App/SessionCoordinator.swift`, `Hyperfocus/Orb/FocusOrbWindowController.swift`
  - Coordinator executes `.showStartCard`/`.hideStartCard` using a `KeyablePanel` positioned next to the orb (canon §3 window inventory); typing in the mission field must work (gotcha §3.1).
  - Accept: manual — click orb → card appears adjacent, keyboard input works, Cancel/Esc closes it.

**Corner cases:** empty and whitespace-only mission cannot start; custom duration clamped to 1–180; cancel from preparing leaves no timer/camera/aura side effects; reopening the card starts clean.

### Phase 4 — Countdown

**Goal:** cinematic fullscreen countdown with voice, plus the abort path.
**Definition of Done:** T4/T5 tests green; sequence `ENTER HYPERFOCUS MODE` → `3` → `2` → `1` → `FOCUS` renders with darkening and voice; Esc aborts with nothing saved.
**Depends on:** Phase 3 (T3 emits `.showCountdown`).

- [x] **4.1 T4 (TDD)**
  - Files: `Hyperfocus/Session/SessionReducer.swift`, `HyperfocusTests/SessionReducerTests.swift`
  - RED: `test_T4_countdown_countdownCompleted_toActive_emitsDismissCountdown_setAuraGreen_startTimer_startPresenceDetection`
  - Accept: test green.
- [x] **4.2 T5 (TDD)**
  - Files: same as 4.1
  - RED: `test_T5_countdown_userExited_toIdle_emitsDismissCountdown_stopCamera_andDoesNotSave` (abort: no `.saveSession` effect emitted).
  - Accept: test green.
- [ ] **4.3 Countdown overlay window + view**
  - Files: `Hyperfocus/UI/CountdownOverlayView.swift`, `Hyperfocus/Utilities/OverlayWindow.swift`
  - Borderless `NSWindow` at main-screen frame, level `.screenSaver` (canon §3); darkened background honoring `hf.darkenScreenOnStart`; animated text sequence with fade / light scale / soft glow; sends `.countdownCompleted` when finished.
  - Accept: build green; manual run shows the full sequence then dismisses.
- [ ] **4.4 Voice service + countdown line**
  - Files: `Hyperfocus/Audio/VoicePrompting.swift`, `Hyperfocus/Audio/VoicePromptService.swift`, `Hyperfocus/App/SessionCoordinator.swift`
  - `AVSpeechSynthesizer` implementation of `VoicePrompting`; style params per canon §6 (calm 0.45/1.0, strict 0.52/0.95, cinematic 0.42/0.85); `.playVoice(.countdown)` speaks exactly `Enter Hyperfocus Mode. Three. Two. One. Focus.`; respects `hf.voicePromptsEnabled`.
  - Accept: manual — voice plays in sync with the visuals.
- [ ] **4.5 Abort wiring**
  - Files: `Hyperfocus/UI/CountdownOverlayView.swift`, `Hyperfocus/App/SessionCoordinator.swift`
  - Esc during countdown sends `.userExited` (T5).
  - Accept: manual — Esc mid-countdown returns to idle: no aura, no timer, `sessions.json` unchanged.

**Corner cases:** abort mid-countdown leaves zero side effects; `hf.voicePromptsEnabled = false` still shows the visual sequence; `hf.darkenScreenOnStart = false` skips darkening but keeps the text; countdown targets `NSScreen.main` at session start.

### Phase 5 — Aura

**Goal:** 4 click-through edge glow windows driven by `AuraState`.
**Definition of Done:** aura shows green/yellow/red/dimmed, flashes-then-hides, never intercepts clicks or focus, rebuilds on screen change.
**Depends on:** Phase 1 (coordinator). Parallel-safe with Phase 4.

- [ ] **5.1 OverlayWindow factory**
  - Files: `Hyperfocus/Utilities/OverlayWindow.swift`
  - Borderless, `isOpaque = false`, clear background, `hasShadow = false`, `ignoresMouseEvents = true`, level `.statusBar`, collectionBehavior `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` (canon §3 aura row).
  - Accept: build green.
- [ ] **5.2 AuraWindowController + geometry**
  - Files: `Hyperfocus/Aura/AuraWindowController.swift`, `Hyperfocus/Utilities/ScreenManager.swift`
  - Four edge strips (top/bottom/left/right) on `NSScreen.main`, each 120 pt thick × `hf.auraThickness` (0.5–1.5), spanning the full edge; corner overlap is acceptable; ordered with `orderFrontRegardless()`, never `makeKey` (canon §3.3).
  - Accept: manual — windows cover all edges; clicks pass through to apps beneath.
- [ ] **5.3 AuraFrameView gradient**
  - Files: `Hyperfocus/Aura/AuraFrameView.swift`, `Hyperfocus/Aura/AuraState.swift`
  - Linear gradient from `edgeColor.opacity(0.55 × auraIntensity)` at the screen edge to `.clear` inward (canon §3); colors for `.green`, `.yellow`, `.red`, `.dimmed`; `hf.auraIntensity` (0.2–1.0) applied.
  - Accept: manual — glow is subtle and peripheral, does not block reading.
- [ ] **5.4 State transitions + flashThenHide**
  - Files: `Hyperfocus/Aura/AuraWindowController.swift`
  - Smooth animated color transitions; `.flashThenHide` = green flash then fade out; `.hidden` removes the windows.
  - Accept: manual cycle through all `AuraState` cases.
- [ ] **5.5 Coordinator wiring + screen-change rebuild**
  - Files: `Hyperfocus/App/SessionCoordinator.swift`, `Hyperfocus/App/AppDelegate.swift`
  - Coordinator executes `.setAura(_)`; on `didChangeScreenParametersNotification` rebuild aura windows (canon §3.6).
  - Accept: manual — a resolution change rebuilds the frame correctly.

**Corner cases:** aura never steals key/focus; clicks at extreme screen edges reach the app beneath; intensity/thickness at both range ends stay usable; no aura in `idle`.

### Phase 6 — Timer engine

**Goal:** monotonic 1 Hz timer plus full reducer time accounting and the manual-pause / complete / exit transitions.
**Definition of Done:** T13, T14, T15, T16 (from `active`/`manualPaused`), T18 tests green; all canon §4 accounting rules covered by named tests; HUD shows live remaining time.
**Depends on:** Phase 4 (T4 starts the timer).

- [x] **6.1 SessionTimer (TDD)**
  - Files: `Hyperfocus/Session/SessionTimer.swift`, `HyperfocusTests/SessionTimerTests.swift`
  - RED: `test_tickCarriesMonotonicDelta`, `test_deltaUsesMonotonicClockNotWallClock`, `test_stopPreventsFurtherTicks` (injectable clock; 1 Hz on the main run loop; deltas from `ContinuousClock` / `CACurrentMediaTime()`).
  - Accept: tests green.
- [x] **6.2 Tick accounting (TDD)**
  - Files: `Hyperfocus/Session/SessionReducer.swift`, `Hyperfocus/Session/SessionContext.swift`, `HyperfocusTests/SessionReducerTests.swift`
  - RED: `test_tick_active_decrementsRemaining_incrementsActiveFocus`, `test_tick_decrementClampedTo1Second`, `test_tick_deltaOver5s_excessAddsToPausedSeconds`, `test_tick_warning_stillDecrementsRemaining`.
  - Accept: tests green (canon §4 accounting rules).
- [x] **6.3 Streak accounting (TDD)**
  - Files: same as 6.2
  - RED: `test_currentStreak_growsWithActiveFocus`, `test_longestStreak_isMaxOfCurrent_updatedEveryTick`, `test_streak_notResetOnWarning`.
  - Accept: tests green.
- [x] **6.4 T13/T14 manual pause (TDD)**
  - Files: same as 6.2
  - RED: `test_T13_active_userPaused_toManualPaused_emitsPauseTimer_setAuraDimmed`, `test_T14_manualPaused_userResumed_toActive_emitsResumeTimer_setAuraGreen`, `test_manualPaused_accruesPausedSeconds_resetsStreak_doesNotIncrementBreakCount`.
  - Accept: tests green.
- [x] **6.5 T15 completion on zero (TDD)**
  - Files: same as 6.2
  - RED: `test_T15_active_tickToZero_toCompleted_emitsStopTimer_stopCamera_stopAlarm_setAuraFlashThenHide_playVoiceComplete_showCompletion`, `test_T15_warning_tickToZero_toCompleted`.
  - Accept: tests green.
- [x] **6.6 T16 (active/manualPaused) + T18 (TDD)**
  - Files: same as 6.2
  - RED: `test_T16_active_userExited_toExited_emitsStopAll_saveSessionExited`, `test_T16_manualPaused_userExited_toExited`, `test_T18_exited_immediatelyReturnsToIdle`.
  - Accept: tests green.
- [ ] **6.7 Coordinator timer wiring + HUD**
  - Files: `Hyperfocus/App/SessionCoordinator.swift`, `Hyperfocus/Session/SessionTimer.swift`, `Hyperfocus/UI/ActiveHUDView.swift`
  - Coordinator executes `.startTimer`/`.pauseTimer`/`.resumeTimer`/`.stopTimer` against `SessionTimer`; ticks feed `SessionEvent.tick(deltaSeconds:)` back into the reducer. `ActiveHUDView` near the orb shows Mission / remaining time / session status / Exit (camera status string added in Phase 7).
  - Accept: manual — start a 5-minute session, HUD counts down; pause/resume works.

**Corner cases (canon §4 accounting / `specs/03-state-machine.md`):** machine sleep during `active` (delta > 5 s → excess to `pausedSeconds`, decrement capped at 1 s); ticks in `away`/`manualPaused`/`recovering` never decrement `remainingFocusTime`; remaining never goes negative; completion fires exactly at zero, including from `warning`; exit from `manualPaused` saves `completionStatus = .exited`.

### Phase 7 — Camera presence

**Goal:** real AVFoundation + Vision presence detection behind `PresenceDetecting`, plus the simulated service and the no-camera fallback.
**Definition of Done:** debug menu drives presence events end-to-end; real camera emits change-only events with detection ≤ 2 Hz; permission and no-camera paths handled; camera fully torn down on `stopCamera`.
**Depends on:** Phase 6 (tick/presence plumbing in reducer context).

- [ ] **7.1 SimulatedPresenceService + Debug menu**
  - Files: `Hyperfocus/Camera/SimulatedPresenceService.swift`, `Hyperfocus/Camera/PresenceDetecting.swift`, `Hyperfocus/App/HyperfocusApp.swift`
  - Menu items exactly per canon §10: `Simulate: Face Present`, `Simulate: Face Missing`, `Simulate: Jump to Away` (fast-forwards `faceMissingSeconds` to `awayThresholdSeconds`), `Simulate: Return`, `Use Simulated Camera` (toggle, applies to next session); `#if DEBUG` only.
  - Accept: manual — simulated events reach the reducer as `.facePresenceChanged`.
- [ ] **7.2 CameraPermissionService**
  - Files: `Hyperfocus/Camera/CameraPermissionService.swift`
  - Authorization status + request; surfaces `CameraState.notAuthorized`.
  - Accept: manual — fresh permission prompt shows the canon §11 `NSCameraUsageDescription` string.
- [ ] **7.3 CameraPresenceService capture + detection**
  - Files: `Hyperfocus/Camera/CameraPresenceService.swift`
  - `AVCaptureSession` preset `.vga640x480`, frames on the `com.hyperfocus.camera` serial queue, `VNDetectFaceRectanglesRequest` at most every 0.5 s (drop frames between), events delivered on main, emitted only when the detected value CHANGES plus one initial value; `startWarmup()` pre-rolls during countdown (canon §6).
  - Accept: manual — face present/absent flips HUD status within ~1 s.
- [ ] **7.4 Teardown + privacy invariants**
  - Files: `Hyperfocus/Camera/CameraPresenceService.swift`, `Hyperfocus/App/SessionCoordinator.swift`
  - `.stopCamera` → `stopRunning`, remove inputs/outputs. Verify canon §6 privacy invariants: `grep -rE "AVCaptureMovieFileOutput|AVAssetWriter|URLSession" Hyperfocus/` returns nothing; no `CVPixelBuffer`/`CGImage` writes anywhere.
  - Accept: macOS camera indicator turns off within seconds of session end; grep is clean.
- [ ] **7.5 No-camera fallback + HUD status strings**
  - Files: `Hyperfocus/App/SessionCoordinator.swift`, `Hyperfocus/UI/ActiveHUDView.swift`, `Hyperfocus/Camera/CameraPermissionService.swift`
  - If `notAuthorized`/`unavailable` or `hf.useCameraForPresence = false`, and `hf.allowSessionsWithoutCamera = true`: session runs in manual mode — presence events never fire; only manual pause and exit change the running state (canon §4). HUD camera status uses exactly: `Present`, `Looking for you`, `Away`, `Camera off`, `Permission needed`.
  - Accept: manual — deny permission, session still starts, HUD shows `Camera off`.
- [x] **7.6 Camera loss mid-session — `.cameraStateChanged` reducer handling (D1) (TDD)**
  - Files: `Hyperfocus/Session/SessionReducer.swift`, `Hyperfocus/Session/SessionContext.swift`, `HyperfocusTests/SessionReducerTests.swift`
  - When `.cameraStateChanged(.unavailable / .disabled / .notAuthorized)` arrives during a running session: in `active` — stay in `active`, presence-driven transitions disabled, timer keeps running, HUD shows `Camera off`; in `warning` — return to `active` applying T7's effect list, `faceMissingSeconds` resets; in `away` or `recovering` — treat exactly as `.facePresenceChanged(true)`: away → `recovering` (T10), then after `recoverySeconds` → `active` (T12, alarm stops, timer resumes). A session must never stay stuck with a looping alarm after the camera disappears.
  - RED: `test_cameraLoss_activeStaysActiveTimerRuns`, `test_cameraLoss_warningReturnsToActive`, `test_cameraLoss_awayEntersRecovering` — these names are cataloged in specs/06 §4.7 (Camera degradation), which is authoritative per D5.
  - Accept: tests green.

**Corner cases:** permission denied at session start; camera device unavailable; no-camera session ignores all presence logic; raw camera flicker < 0.5 s absorbed by tick-based `faceMissingSeconds` (canon §4 debouncing); camera never left running after `completed`/`exited`.

### Phase 8 — Away mode

**Goal:** the full presence loop — warning at 7 s, away at 15 s, alarm, away card, 3 s recovery — every transition test-first against the canon §4 table.
**Definition of Done:** T6–T12 and T16 (from `warning`/`away`/`recovering`) tests green; full manual run via debug menu: green → yellow → red + alarm → recovery countdown → green.
**Depends on:** Phase 5 (aura), Phase 6 (timer/reducer), Phase 7 (presence events).

- [x] **8.1 Presence debounce + T6 (TDD)**
  - Files: `Hyperfocus/Session/SessionReducer.swift`, `Hyperfocus/Session/SessionContext.swift`, `HyperfocusTests/SessionReducerTests.swift`
  - RED: `test_faceMissingSeconds_accumulatesOnTicksWhileMissing_resetsOnFacePresent`, `test_T6_active_tickWithFaceMissing7s_toWarning_emitsSetAuraYellow` (threshold from config, `hf.warningThresholdSeconds` = 7).
  - Accept: tests green.
- [x] **8.2 T7 (TDD)**
  - Files: same as 8.1
  - RED: `test_T7_warning_facePresent_toActive_emitsSetAuraGreen_noRecoveryDelay_counterResets`
  - Accept: test green.
- [x] **8.3 T8/T9 (TDD)**
  - Files: same as 8.1
  - RED: `test_T8_warning_tickWithFaceMissing15s_toAway_emitsSetAuraRed_pauseTimer_startAlarm_playVoiceAway_showAwayCard_incrementsBreakCount_resetsStreak`, `test_T9_active_simulateAway_toAway_sameEffectsAsT8`, `test_breakCount_incrementsOncePerAwayEntry` (`hf.awayThresholdSeconds` = 15).
  - Accept: tests green.
- [x] **8.4 T10/T11/T12 recovery (TDD)**
  - Files: same as 8.1
  - RED: `test_T10_away_facePresent_toRecovering_emitsShowRecoveryCountdown_alarmKeepsPlaying`, `test_T11_recovering_faceLost_toAway_emitsHideRecoveryCountdown`, `test_T12_recovering_facePresent3s_toActive_emitsStopAlarm_hideAwayCard_hideRecoveryCountdown_setAuraGreen_resumeTimer_playVoiceRestored` (`hf.recoverySeconds` = 3).
  - Accept: tests green.
- [x] **8.5 T16 remaining sources (TDD)**
  - Files: same as 8.1
  - RED: `test_T16_warning_userExited_toExited`, `test_T16_away_userExited_toExited_stopsAlarm_hidesAwayCard`, `test_T16_recovering_userExited_toExited`.
  - Accept: tests green.
- [ ] **8.6 AlarmService**
  - Files: `Hyperfocus/Audio/AlarmPlaying.swift`, `Hyperfocus/Audio/AlarmService.swift`
  - Brown noise in an `AVAudioSourceNode` render block per canon §6 (`brown += (white - brown * 0.02); sample = brown * 3.5 × volume`, clamp to [-1, 1]) through `AVAudioEngine.mainMixerNode`; fade in over 0.8 s; loops until `stop()`; volume = `hf.soundVolume` × intensity multiplier (calm 0.7×, strict 1.1×, cinematic 1.0× — canon §8).
  - Accept: manual — soft continuous hum, not a beep; stops instantly on `stop()`.
- [ ] **8.7 Away card + recovery countdown UI**
  - Files: `Hyperfocus/UI/AwayModeView.swift`, `Hyperfocus/UI/GlassCard.swift`
  - `KeyablePanel` centered, level `.screenSaver` (canon §3). Exact §9 copy: title `Session paused`, text `Return to Hyperfocus or exit the session.`, buttons `Return` (enabled only while face visible; affordance only — recovery is automatic) and `Exit Session`; recovery countdown `3` → `2` → `1` → `Back to focus`. Voice on away: `Session paused. Return to Hyperfocus or exit.`; on recovery: `Focus restored.`
  - Accept: manual copy check against §9, string for string.
- [ ] **8.8 End-to-end wiring + full simulated run**
  - Files: `Hyperfocus/App/SessionCoordinator.swift`
  - All Phase 8 effects executed against alarm/aura/voice/card services.
  - Accept: manual via debug menu — `Simulate: Face Missing` → yellow at 7 s → red + alarm + card at 15 s → `Simulate: Return` → 3 s countdown → green, alarm off, timer resumes; timer paused for the whole away/recovering span.

**Corner cases (canon §4 / `specs/03-state-machine.md` themes):** face flickers during recovery (T10↔T11 loop, repeatable without corrupting counters); re-entering `away` after a recovery increments `breakCount` again; alarm stops immediately on both recovery completion and exit; `pausedSeconds` accrues through `away` + `recovering`; streak resets on entering `away` but NOT on `warning`; exit from `recovering` saves `.exited` and silences everything.

### Phase 9 — Completion

**Goal:** completion card, JSON persistence, history list, clean reset to idle.
**Definition of Done:** SessionStore + T17 tests green; a finished session round-trips to `sessions.json` (on disk under App Sandbox: `~/Library/Containers/com.hyperfocus.app/Data/Library/Application Support/Hyperfocus/sessions.json`) and shows in History; orb returns to idle.
**Depends on:** Phase 6 (T15 emits `.showCompletion`), Phase 8 (stats to display).

- [x] **9.1 SessionStore (TDD)**
  - Files: `Hyperfocus/Session/SessionStore.swift`, `HyperfocusTests/SessionStoreTests.swift`
  - RED: `test_append_persistsPrettyPrintedJSON`, `test_all_loadsRoundTrippedSessions`, `test_clear_removesAll`, `test_createsApplicationSupportDirectoryIfMissing` (injectable directory URL per canon §7; API `append(_:)`, `all()`, `clear()`).
  - Note: implementation pre-exists from Phase 0 — write the catalog tests from specs/06 §4 to verify it (they may pass immediately); do not re-stub or rewrite working code. The red-first rule applies only to code that does not exist yet.
  - Accept: tests green.
- [x] **9.2 T17 (TDD)**
  - Files: `Hyperfocus/Session/SessionReducer.swift`, `HyperfocusTests/SessionReducerTests.swift`
  - RED: `test_T17_completed_resultSaved_toIdle_emitsSaveSession_hideCompletion_orbFlash`, `test_resultSaved_carriesNextActionIntoSavedSession`.
  - Accept: tests green.
- [ ] **9.3 Completion card UI**
  - Files: `Hyperfocus/UI/CompletionView.swift`
  - `KeyablePanel` centered, level `.floating` (canon §3). Exact §9 copy: title `Mission complete`, fields Mission / Focus time / Paused time / Breaks / Longest streak, question `Did you complete the mission?`, buttons `Done` / `Partial` / `Not done`, optional field placeholder `Next action`. Voice on completion: `Mission complete.`
  - Accept: manual copy + stats check.
- [ ] **9.4 Save wiring + reset**
  - Files: `Hyperfocus/App/SessionCoordinator.swift`, `Hyperfocus/Session/SessionModel.swift`
  - `.saveSession(status)` maps `SessionContext` → `Session` (all §7 fields incl. `nextAction`, `endedAt`); after T17 the orb returns to idle with `.orbFlash`; T16 exits save `completionStatus: .exited` without showing the completion card.
  - Accept: manual — complete a short session end-to-end; `sessions.json` contains correct counters.
- [ ] **9.5 HistoryView**
  - Files: `Hyperfocus/UI/HistoryView.swift`
  - Simple list per BRIEF: Date / Mission / Duration / Status / Breaks, newest first, from `SessionStore.all()`; opened from the menu bar.
  - Accept: manual — completed and exited sessions both listed.

**Corner cases:** exited session persists with `endedAt` set and no completion card; `nil` `successCondition`/`nextAction` round-trips JSON; zero-break session shows Breaks 0; corrupt or missing `sessions.json` handled without crash (empty history).

### Phase 10 — Polish

**Goal:** settings, onboarding, quick actions, motion/intensity options, final acceptance pass.
**Definition of Done:** every BRIEF acceptance criterion (1–30) passes on a manual walkthrough; build + all tests green from a clean `xcodegen generate`.
**Depends on:** all previous phases.

- [ ] **10.1 SettingsView**
  - Files: `Hyperfocus/UI/SettingsView.swift`, `Hyperfocus/Utilities/SettingsStore.swift`
  - All canon §8 sections/keys: General (launch at login via `SMAppService.mainApp`, show orb on launch, orb size/opacity, reset orb position), Focus (default duration/intensity, warning/away/recovery thresholds, allow sessions without camera), Camera (permission status, use-camera toggle, privacy copy, open system permissions), Sound (voice prompts, alarm, volume, voice style), Visual (aura intensity/thickness, reduce motion, darken screen, cinematic countdown), Data (session history, clear local data). Privacy copy verbatim from canon §9.
  - Accept: manual — every control reads/writes its `hf.*` key.
- [ ] **10.2 OnboardingView**
  - Files: `Hyperfocus/UI/OnboardingView.swift`
  - 5 screens exactly per BRIEF/canon §9 (`Hyperfocus for Mac`, `Enter focus mode`, `Presence check`, `Private by default`, CTA `Start using Hyperfocus`); shown once, gated by `hf.onboardingCompleted`.
  - Accept: manual — fresh defaults show onboarding exactly once.
- [ ] **10.3 Orb quick actions**
  - Files: `Hyperfocus/Orb/FocusOrbWindowController.swift`
  - Right-click / long-press menu per canon §9: `Pause` (session running), `Exit Session` (session running), `Hide for 10 minutes`, `Settings…`. Pause/Exit dispatch `.userPaused`/`.userExited`.
  - Accept: manual — items act correctly; orb reappears after 10 minutes.
- [ ] **10.4 Reduce motion + intensity visuals**
  - Files: `Hyperfocus/UI/CountdownOverlayView.swift`, `Hyperfocus/Aura/AuraFrameView.swift`, `Hyperfocus/Orb/FocusOrbView.swift`
  - `hf.reduceMotion` disables pulses/flashes/scale animations; `hf.cinematicCountdownEnabled` toggles the extra-glow variant; intensity multipliers per canon §8 (aura 0.8× / 1.0× / 1.2×; countdown standard / faster / extra glow with slower scale and longer fades).
  - Accept: manual check per intensity mode.
- [ ] **10.5 Multi-monitor + screen-change hardening**
  - Files: `Hyperfocus/Utilities/ScreenManager.swift`, `Hyperfocus/App/AppDelegate.swift`
  - MVP is single-screen (canon §3.7): overlays target `NSScreen.main` at session start; orb clamps into visible bounds on layout change; aura rebuilds.
  - Accept: manual — unplug/replug a display mid-session; nothing is stranded off-screen.
- [ ] **10.6 Final acceptance pass**
  - Files: none (verification only; any fixes become their own commits).
  - Walk BRIEF Acceptance Criteria 1–30 with both the real camera and `Use Simulated Camera`; run all tests; re-run the privacy grep from 7.4; confirm the canon §1 commands work from a clean checkout.
  - Accept: all 30 criteria pass; record the walkthrough result in `PROGRESS.md`.
- [ ] **10.7 README refresh**
  - Files: `README.md`
  - Write the "Next recommended improvements" section into `README.md` and refresh the feature/limitations lists against what actually shipped.
  - Accept: README matches the shipped MVP — no listed feature is missing, no shipped behavior is undocumented.

**Corner cases:** onboarding never reappears after completion; threshold settings changes apply to the next session; `Clear local data` empties history without crashing an active session; reduce motion leaves all functionality intact.

---

## 5. Phase → transition/test mapping

Every transition Tn from the canon §4 table gets a named unit test in
`HyperfocusTests/SessionReducerTests.swift` BEFORE its implementation. Naming convention:
`test_T<n>_<fromState>_<event>_to<ToState>_<keyEffects>`.

Test names: the `specs/06-testing.md` §4 catalog is authoritative (D5); RED names listed in plan items are informal — on mismatch, 06 §4 wins.

| Phase | Transitions covered (test-first) | Other TDD surfaces |
|---|---|---|
| 2 — Focus Orb | — | `OrbPositionStoreTests` (persist / clamp / default) |
| 3 — Start card | T1, T2, T3 (+ empty-mission rejection) | — |
| 4 — Countdown | T4, T5 | — |
| 6 — Timer engine | T13, T14, T15, T16 (from `active`/`manualPaused`), T18 | `SessionTimerTests` (monotonic delta, 1 s clamp, sleep gap); tick + streak accounting |
| 8 — Away mode | T6, T7, T8, T9, T10, T11, T12, T16 (from `warning`/`away`/`recovering`) | presence debounce (`faceMissingSeconds`); `breakCount`/streak rules |
| 9 — Completion | T17 | `SessionStoreTests` (JSON round-trip) |

Sanity check before closing Phase 9: all 18 transitions (T1–T18) have at least one green test each.

---

## 6. Commit message convention

One checklist item = one commit (`CLAUDE.md` §8: small, atomic, `type: what and why`).
The red test and the green implementation may be one commit per item, or two (`test:` then `feat:`) — never mix refactoring into either.

```
feat: T8 warning→away with alarm, red aura, away card effects
test: failing reducer tests for T10–T12 recovery loop
fix: clamp tick decrement to 1s after machine sleep (canon §4)
refactor: extract edge-snap math from FocusOrbWindowController
chore: add AlarmService to project.yml target membership
docs: update PROGRESS.md after closing Phase 6
```

Never commit: the generated `Hyperfocus.xcodeproj`, temp files, dumps, secrets (`CLAUDE.md` §8–9).

---

## 7. When blocked (CLAUDE.md §11)

- **2–3 failed attempts on one checklist item → STOP.** Do not keep hammering blind.
- Write in `PROGRESS.md`: item id, what was tried (one line per attempt), the exact error/symptom, current hypothesis, and what input is needed. Then report and ask — never silently skip or work around a blocked item.
- If a canon detail turns out wrong or unimplementable: per canon precedence rules, update `specs/00-canon.md` first (one dedicated commit stating the deviation), then the dependent code. Never deviate silently.
- Scope creep (an item grows beyond one commit): stop, split it into new checklist items in this file, note the split in `PROGRESS.md`, then continue one item at a time.
- Destructive/irreversible operations (deleting user data paths, `--force` pushes, etc.): forbidden without explicit human confirmation; fix a rollback path first.

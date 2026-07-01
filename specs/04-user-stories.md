# 04 — User Stories & Acceptance Criteria

> Derived from `specs/BRIEF.md` (product truth) and `specs/00-canon.md` (technical truth).
> All identifiers, thresholds, copy strings, settings keys, and file paths below are canon — do not paraphrase.
> Verification references the canon test targets: `SessionReducerTests`, `SessionTimerTests`, `SessionStoreTests`, `OrbPositionStoreTests` (unit), plus manual steps and the `Debug` menu simulation (§10 of canon).

Roles: **user with ADHD** (primary), **developer** (debug simulation only).

---

## Launch & orb

**US-1: As a user with ADHD, I want a small glass Focus Orb to appear when I launch the app, so that focus mode is always one click away without cluttering my screen.**
Acceptance criteria:
- Given a first launch (after onboarding), when the app starts, then the orb appears as an always-on-top `KeyablePanel` (level `.statusBar`, `[.canJoinAllSpaces, .fullScreenAuxiliary]`), default size 22 pt (`hf.orbSize`, range 18–24), opacity 0.9 (`hf.orbOpacity`), default position bottom-right at 8 pt margin.
- The app has no Dock icon (`LSUIElement = true`); a `MenuBarExtra` provides Settings / History / Quit.
- If `hf.showOrbOnLaunch` is false, the orb does not appear on launch.
- The orb never blocks typing or clicks in other apps; it only reacts to direct interaction.
Verification: manual — launch via `xcodebuild ... build` + open; confirm orb bottom-right, no Dock icon, menu bar item present. Toggle `hf.showOrbOnLaunch` via `defaults write com.hyperfocus.app hf.showOrbOnLaunch -bool false` and relaunch.

**US-2: As a user with ADHD, I want to drag the orb and have it snap to screen edges, so that I can park it where it never distracts me.**
Acceptance criteria:
- Given a mouse-down on the orb, when I move ≥ 4 pt or hold ≥ 0.3 s, then it is a drag (panel frame follows cursor via `NSEvent` tracking, not `isMovableByWindowBackground`); a mouseUp is a click only when movement is strictly < 4 pt AND duration is strictly < 0.3 s.
- When drag ends with the orb center within 32 pt of a screen edge, then the orb animates to an 8 pt margin from that edge.
- When drag ends farther than 32 pt from every edge, the orb stays where dropped.
Verification: manual drag near each of the 4 edges (snap) and to screen center (no snap) — manual QA step 3 in `specs/06-testing.md` §5 and the `specs/05-implementation-plan.md` Phase 2 item 2.4 acceptance check (drag/snap is window behavior, deliberately not unit-tested — specs/06 §1.2).

**US-3: As a user with ADHD, I want the orb to remember its position across launches and stay on visible screen bounds, so that my setup survives restarts and display changes.**
Acceptance criteria:
- Orb position persists as JSON `{x,y}` under `hf.orbPosition`; restored on next launch.
- On `NSApplication.didChangeScreenParametersNotification`, the orb is clamped into `NSScreen.main.visibleFrame` (and aura windows are rebuilt).
- Settings → General "Reset orb position" returns the orb to bottom-right, 8 pt margin.
Verification: unit `OrbPositionStoreTests.testPersistRestorePosition`, `testClampIntoVisibleBounds`; manual — move orb, quit, relaunch; disconnect/resize display while orb sits at an edge that disappears.

**US-4: As a user with ADHD, I want a quick-actions menu on the orb, so that I can pause, exit, hide, or reach settings without hunting for windows.**
Acceptance criteria:
- Right-click (or long-press) the orb opens a menu with exactly: `Pause` (enabled only while the session state is `active` — disabled/hidden in `warning` and every other state, canon T13), `Exit Session` (only while a session is running), `Hide for 10 minutes`, `Settings…`.
- `Hide for 10 minutes` hides the orb; it reappears automatically after 10 minutes.
- `Pause` dispatches `.userPaused`; `Exit Session` dispatches `.userExited`; `Settings…` opens the Settings window.
Verification: manual — right-click in idle (Pause/Exit absent or disabled) and during an active session (all four actions); confirm orb reappears after the hide interval (shorten interval in a debug build if needed).

---

## Start card & validation

**US-5: As a user with ADHD, I want clicking the orb to open a compact glass "Prepare Hyperfocus" card where I name one mission, so that I commit to a single task before starting.**
Acceptance criteria:
- Given `idle`, when I click the orb, then `.orbClicked` → state `preparing`, effect `.showStartCard` (T1); the card is a `KeyablePanel` positioned next to the orb, not fullscreen.
- Title `Prepare Hyperfocus`, subtitle `One task. One session.`.
- Mission field placeholder: `What are you doing in this session?` — the field accepts keyboard input (KeyablePanel `canBecomeKey == true`).
- Success condition field placeholder: `This session is successful if…` — optional, may be left empty.
- `Cancel` dispatches `.cancelPreparing` → `idle`, `.hideStartCard` (T2); nothing is saved.
Verification: unit `SessionReducerTests.testT1_orbClicked_showsStartCard`, `testT2_cancelPreparing_returnsIdle`; manual — click orb, type into mission field immediately (no extra click on the panel required), press Cancel.

**US-6: As a user with ADHD, I want duration presets and an intensity choice on the start card, so that starting takes seconds instead of configuration.**
Acceptance criteria:
- Duration presets: `5`, `15`, `25`, `45` minutes + `Custom` (1–180 via stepper or text). Default preselected = `hf.defaultDurationMinutes` (25).
- Intensity selector: `Calm`, `Strict`, `Cinematic`; default preselected = `hf.defaultIntensity` (`cinematic`).
- The chosen values populate `SessionConfig` (mission, duration, intensity, cameraEnabled) passed with `.enterHyperfocus(config)`.
- Custom values outside 1–180 are rejected/clamped by the input control.
Verification: manual — select each preset and a custom value (e.g. 1, 180; try 0 and 181 → rejected); unit test on `SessionConfig` construction if validation lives in a testable layer.

**US-7: As a user with ADHD, I want the app to refuse to start without a mission, so that I never begin an unfocused session.**
Acceptance criteria:
- Given an empty (or whitespace-only) mission, the `Enter Hyperfocus` CTA is disabled — the session cannot start.
- Given a non-empty mission, `Enter Hyperfocus` dispatches `.enterHyperfocus(config)` → `countdown` (T3).
- The reducer also guards: `.enterHyperfocus` with an empty mission produces no transition.
Verification: unit `SessionReducerTests.testT3_enterHyperfocus_emptyMission_noTransition`, `testT3_enterHyperfocus_validMission_startsCountdown`; manual — CTA disabled until a character is typed.

---

## Countdown

**US-8: As a user with ADHD, I want a cinematic fullscreen countdown when I start, so that entering focus feels like a mode switch, not a timer click.**
Acceptance criteria:
- On T3: effects `.hideStartCard`, `.showCountdown`, `.playVoice(.countdown)`, `.startCameraWarmup`; countdown window is a borderless `NSWindow` at main-screen frame, level `.screenSaver`.
- The screen darkens (respecting `hf.darkenScreenOnStart`); text sequence displays exactly: `ENTER HYPERFOCUS MODE` → `3` → `2` → `1` → `FOCUS`, with fade/scale/glow animations (reduced when `hf.reduceMotion` is true; standard/faster/extra-glow variants per intensity table in canon §8).
- Voice speaks exactly: `Enter Hyperfocus Mode. Three. Two. One. Focus.` (skipped when `hf.voicePromptsEnabled` is false).
- After `FOCUS`, `.countdownCompleted` → `active` with `.dismissCountdown`, `.setAura(.green)`, `.startTimer`, `.startPresenceDetection` (T4).
- If `hf.cinematicCountdownEnabled` is false, the standard (non-cinematic) countdown variant is used; the overlay is never skipped, and the `countdown` state and `.countdownCompleted` timing are unchanged.
Verification: unit `SessionReducerTests.testT3_effects`, `testT4_countdownCompleted_activatesSession`; manual — watch full sequence, confirm voice, confirm green aura appears right after `FOCUS`.

**US-9: As a user with ADHD, I want to abort during the countdown, so that a mis-click doesn't lock me into a session.**
Acceptance criteria:
- Given `countdown`, when `.userExited` fires (Esc key or exit affordance), then state → `idle` with `.dismissCountdown`, `.stopCamera` (T5).
- Nothing is saved — no `Session` record is appended for an aborted countdown.
Verification: unit `SessionReducerTests.testT5_userExitedDuringCountdown_abortsWithoutSaving`; manual — start, press Esc during `3`, confirm no aura, no timer, and `sessions.json` unchanged.

---

## Aura

**US-10: As a user with ADHD, I want a subtle colored glow on the screen edges that tracks my session state, so that I sense my status peripherally without reading anything.**
Acceptance criteria:
- 4 borderless edge windows (top/bottom/left/right) on `NSScreen.main`, level `.statusBar`, `ignoresMouseEvents = true`, `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` — clicks pass through; the aura never steals focus (never `makeKey`; `orderFrontRegardless()`).
- Each strip is 120 pt × `hf.auraThickness`, linear gradient from `edgeColor.opacity(0.55 × auraIntensity)` at the edge to `.clear` inward (auraIntensity = `hf.auraIntensity` × intensity multiplier 0.8/1.0/1.2 for calm/strict/cinematic).
- `AuraState` mapping: `hidden` (idle), `green` (active), `yellow` (warning), `red` (away), `dimmed` (manualPaused), `flashThenHide` (completed).
- State transitions animate smoothly; with `hf.reduceMotion` true, transitions are instant/minimal.
Verification: manual — during a session, click and type into another app through an edge region (must work); drive `green → yellow → red → green` via Debug menu; unit — reducer tests assert the `.setAura(...)` effect per transition.

---

## Timer

**US-11: As a user with ADHD, I want the timer to count only real focus time, accurately, so that my session stats reflect actual work.**
Acceptance criteria:
- `SessionTimer` ticks at 1 Hz on the main run loop; each `.tick(deltaSeconds:)` uses a monotonic clock (`ContinuousClock` / `CACurrentMediaTime()`), not wall clock.
- Per-tick decrement of `remainingFocusTime` is clamped to 1 s; if `delta > 5 s` (sleep/stall), the excess goes to `pausedSeconds`, never to focus time.
- `remainingFocusTime` decreases and `activeFocusSeconds` increases only in `active` and `warning`; `pausedSeconds` accumulates in `away`, `recovering`, `manualPaused`.
- `currentStreakSeconds` grows with active focus; resets to 0 on entering `away` or `manualPaused` (NOT on `warning`); `longestStreakSeconds = max(longestStreakSeconds, currentStreakSeconds)` every tick.
- `breakCount` increments exactly once per entry into `away`; manual pause does not increment it.
Verification: unit `SessionTimerTests.testMonotonicDelta`, `testClampOneSecondPerTick`, `testSleepGapCountsAsPaused`; `SessionReducerTests.testAccounting_streakResetOnAwayNotWarning`, `testBreakCountOnlyOnAwayEntry`; manual — put Mac to sleep 30 s mid-session, wake, confirm remaining time did not jump.

---

## Camera & presence

**US-12: As a user with ADHD, I want camera permission requested only when a camera session needs it, with a plain privacy explanation, so that I can trust the presence check.**
Acceptance criteria:
- On first camera-enabled session start, `CameraPermissionService` checks authorization; if `.notDetermined`, the system prompt appears with usage string: `Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally and never recorded or uploaded.` (`NSCameraUsageDescription`).
- If granted → capture starts (`.vga640x480`, Vision `VNDetectFaceRectanglesRequest` throttled to 2 Hz on `com.hyperfocus.camera` serial queue).
- If denied/unavailable → `CameraState` becomes `.notAuthorized` / `.unavailable`, HUD shows `Permission needed` / `Camera off`, and the no-camera fallback (US-31) is offered per `hf.allowSessionsWithoutCamera`.
- Settings → Camera shows current permission status and can open System Settings camera pane.
Verification: manual — `tccutil reset Camera com.hyperfocus.app`, start a session, observe prompt; deny and confirm fallback offer; check entitlement `com.apple.security.device.camera = true` in the built app.

**US-13: As a user with ADHD, I want the timer to run while my face is visible, so that presence — not willpower — drives the session.**
Acceptance criteria:
- With detection running and a face detected, presence events arrive on the main thread; state stays `active`, aura green, `remainingFocusTime` decreasing.
- `CameraPresenceService` emits an event only when the detected value changes (plus one initial value) — no event spam.
- `faceMissingSeconds` accumulates on ticks while last raw presence is `false` and resets to 0 on any `facePresent`; flicker shorter than one 0.5 s detection interval is absorbed.
Verification: manual — sit in frame 60 s, timer decreases monotonically, HUD shows `Present`; unit `SessionReducerTests.testFaceMissingSecondsResetOnPresence`; debug simulation `Simulate: Face Present`.

**US-14: As a user with ADHD, I want a gentle yellow warning when I've been out of frame for 7 seconds, so that I get nudged back before the session pauses.**
Acceptance criteria:
- Given `active`, when `.tick` finds `faceMissingSeconds ≥ warningThresholdSeconds` (default 7, key `hf.warningThresholdSeconds`), then state → `warning` with `.setAura(.yellow)` (T6).
- In `warning`, the timer keeps running (remaining time still decreases); HUD status shows `Looking for you`.
- Given `warning`, when `.facePresenceChanged(true)` arrives, then state → `active`, `.setAura(.green)` — no recovery delay, counter resets (T7).
Verification: unit `SessionReducerTests.testT6_warningAfter7s`, `testT7_warningRecoversImmediately`, `testWarning_timerStillRuns`; debug — `Simulate: Face Missing`, wait 7 s, aura yellow; `Simulate: Face Present`, aura green instantly.

**US-15: As a user with ADHD, I want the session to pause loudly but kindly when I've been gone 15 seconds, so that wandering off never silently burns my focus time.**
Acceptance criteria:
- Given `warning` (or direct debug jump from `active`, T9), when `.tick` finds `faceMissingSeconds ≥ awayThresholdSeconds` (default 15, key `hf.awayThresholdSeconds`), then state → `away` (T8) with effects: `.setAura(.red)`, `.pauseTimer`, `.startAlarm`, `.playVoice(.away)`, `.showAwayCard`; `ctx.breakCount += 1`; streak resets.
- Alarm is a continuous brown-noise loop (`AVAudioEngine` + `AVAudioSourceNode`, fade-in 0.8 s), volume = `hf.soundVolume` × intensity multiplier (0.7/1.1/1.0), no harsh beeps; disabled entirely when `hf.alarmEnabled` is false.
- Voice speaks exactly: `Session paused. Return to Hyperfocus or exit.`
- Away card (KeyablePanel, centered, level `.screenSaver`): title `Session paused`, text `Return to Hyperfocus or exit the session.`, buttons `Return` and `Exit Session`. `Return` is enabled only while the face is visible (affordance — actual resume is automatic).
- Timer is fully paused: `remainingFocusTime` frozen, `pausedSeconds` accumulating; HUD status `Away`.
Verification: unit `SessionReducerTests.testT8_awayEffects`, `testT8_breakCountIncrements`, `testT9_directAway`; debug — `Simulate: Jump to Away`; manual — leave frame 15 s: red aura, alarm audible, card visible, voice heard.

**US-16: As a user with ADHD, I want the session to resume automatically after I'm back for 3 seconds, so that recovery requires zero interaction.**
Acceptance criteria:
- Given `away`, when `.facePresenceChanged(true)`, then state → `recovering` with `.showRecoveryCountdown` — the alarm keeps playing during recovery (T10).
- Recovery countdown displays exactly: `3` → `2` → `1` → `Back to focus`.
- Given `recovering`, when `.facePresenceChanged(false)`, then state → `away` with `.hideRecoveryCountdown` (T11) — leaving mid-recovery cancels it.
- Given `recovering`, when `.tick` finds face present and `recoveryElapsed ≥ recoverySeconds` (default 3, key `hf.recoverySeconds`), then state → `active` (T12) with `.stopAlarm`, `.hideAwayCard`, `.hideRecoveryCountdown`, `.setAura(.green)`, `.resumeTimer`, `.playVoice(.restored)`.
- Voice speaks exactly: `Focus restored.`
Verification: unit `SessionReducerTests.testT10_awayToRecovering`, `testT11_faceLostDuringRecovery_backToAway`, `testT12_recoveryCompletes`; debug — `Simulate: Return` after away, then `Simulate: Face Missing` at count `2` (must fall back to away), then full recovery.

**US-17: As a user with ADHD, I want to pause and resume manually, so that planned interruptions don't count as broken focus.**
Acceptance criteria:
- Given `active`, `.userPaused` (orb quick action `Pause`) → `manualPaused` with `.pauseTimer`, `.setAura(.dimmed)` (T13).
- In `manualPaused`: timer frozen, `pausedSeconds` accumulating, `currentStreakSeconds` reset, `breakCount` NOT incremented, no alarm, no away card.
- `.userResumed` → `active` with `.resumeTimer`, `.setAura(.green)` (T14) — no 3 s recovery delay.
Verification: unit `SessionReducerTests.testT13_manualPause`, `testT14_manualResume`, `testManualPause_noBreakCount`; manual — Pause via quick actions, wait, resume, check completion stats show paused time but Breaks = 0.

**US-18: As a user with ADHD, I want to exit a session at any point, so that I stay in control without fighting the app.**
Acceptance criteria:
- `.userExited` from `active`, `warning`, `away`, `recovering`, or `manualPaused` → `exited` (T16) with `.stopTimer`, `.stopCamera`, `.stopAlarm`, `.setAura(.hidden)`, `.hideAwayCard`, `.saveSession(status: .exited)`.
- `exited` immediately transitions to `idle` (T18); the orb returns to idle visuals.
- The saved `Session` has `completionStatus == .exited`, real `activeFocusSeconds`/`pausedSeconds`/`breakCount`/`longestStreakSeconds`, and `endedAt` set.
- Exit is reachable via: away card `Exit Session` button, orb quick action `Exit Session`, and the HUD exit button.
Verification: unit `SessionReducerTests.testT16_userExited_fromEachState` (parameterized over the 5 source states), `testT18_exitedToIdle`; manual — exit from away card, confirm alarm stops instantly and a session with status `exited` appears in History.

---

## Completion & history

**US-19: As a user with ADHD, I want a calm completion screen with real stats when the timer hits zero, so that I close the loop on the mission.**
Acceptance criteria:
- Given `active` or `warning`, when `.tick` brings `remainingFocusTime == 0`, then state → `completed` (T15) with `.stopTimer`, `.stopCamera`, `.stopAlarm`, `.setAura(.flashThenHide)`, `.playVoice(.complete)`, `.showCompletion`.
- Voice speaks exactly: `Mission complete.` The aura flashes green then fades out.
- Completion card (KeyablePanel, centered, level `.floating`): title `Mission complete`, fields Mission / Focus time / Paused time / Breaks / Longest streak populated from `SessionContext`, question `Did you complete the mission?`.
- No shaming language appears anywhere on the card.
Verification: unit `SessionReducerTests.testT15_completionAtZero`, `testT15_alsoFiresFromWarning`; manual — run a 1-minute custom session to zero (or debug-accelerate), verify stats match observed pauses/breaks.

**US-20: As a user with ADHD, I want to mark the result (Done / Partial / Not done) and optionally note a next action, so that history reflects honest outcomes.**
Acceptance criteria:
- Buttons exactly: `Done` / `Partial` / `Not done` → `CompletionStatus` `.done` / `.partial` / `.notDone`; optional text field placeholder `Next action`.
- Choosing a result dispatches `.resultSaved(status, nextAction:)` → `idle` (T17) with `.saveSession(status)`, `.hideCompletion`, `.orbFlash`.
- The persisted `Session` (canon §7) carries all fields: `id`, `mission`, `successCondition`, `plannedDurationSeconds`, `activeFocusSeconds`, `pausedSeconds`, `breakCount`, `longestStreakSeconds`, `completionStatus`, `startedAt`, `endedAt`, `intensity`, `cameraEnabled`, `nextAction`.
Verification: unit `SessionReducerTests.testT17_resultSaved`, `SessionStoreTests.testAppendPersistsAllFields` (round-trip Codable equality); manual — complete a session, pick `Partial`, type a next action, inspect `~/Library/Containers/com.hyperfocus.app/Data/Library/Application Support/Hyperfocus/sessions.json` (App Sandbox container path).

**US-21: As a user with ADHD, I want the camera, audio, and overlays to shut down cleanly after every session, so that nothing lingers when I'm done.**
Acceptance criteria:
- On `completed` and `exited`: `.stopCamera` tears down the capture session (`stopRunning`, inputs/outputs removed); the camera indicator LED goes off; `.stopAlarm` and voice stop cleanly.
- After `.resultSaved` (or exit), the aura is hidden, all session windows (HUD, away card, completion card, countdown) are closed, and the orb shows idle state (glass translucent dot; `.orbFlash` plays a brief green flash on save).
- A new session can start immediately after — no leaked windows, timers, or capture sessions (no memory growth across repeated sessions).
Verification: manual — complete a session, confirm camera LED off and orb idle; run 3 back-to-back sessions and confirm no stray windows; unit — reducer tests assert `.stopCamera` present in T15/T16 effect lists.

**US-22: As a user with ADHD, I want a minimal HUD showing my mission, remaining time, and camera status, so that I can check state at a glance without breaking flow.**
Acceptance criteria:
- During a session, the HUD appears near the orb (or on hover) showing: Mission, Remaining time (mm:ss), camera status, session status, and an exit button.
- Camera status displays exactly one of: `Present`, `Looking for you`, `Away`, `Camera off`, `Permission needed`.
- HUD is compact glass styling; it does not cover screen center and never takes focus from the frontmost app except on direct interaction.
Verification: manual — hover the orb during a session; drive each status via Debug menu (`Present` → `Looking for you` → `Away`) and no-camera mode (`Camera off`); revoked permission shows `Permission needed`.

**US-23: As a user with ADHD, I want a simple local session history, so that I can see what I actually focused on recently.**
Acceptance criteria:
- History (via `MenuBarExtra` → History, `HistoryView`) lists recent sessions with: date, mission, duration, status, breaks.
- Data source is `SessionStore` reading `sessions.json` under `FileManager.applicationSupportDirectory/Hyperfocus/` (pretty-printed JSON, directory created if missing; under App Sandbox this resolves on disk to `~/Library/Containers/com.hyperfocus.app/Data/Library/Application Support/Hyperfocus/sessions.json` — use that path for manual inspection); no cloud, no network.
- Sessions appear in the list immediately after being saved (completed and exited both).
Verification: unit `SessionStoreTests.testLoadSaveRoundTrip`, `testCreatesDirectoryIfMissing` (injectable directory URL); manual — complete one session and exit another, open History, both rows correct.

---

## Settings

**US-24: As a user with ADHD, I want General settings for launch and orb appearance, so that the app fits my machine and eyes.**
Acceptance criteria:
- Section contains: Launch at login (`hf.launchAtLogin`, via `SMAppService.mainApp`), Show Focus Orb on launch (`hf.showOrbOnLaunch`), Orb size (`hf.orbSize`, 18–24, default 22), Orb opacity (`hf.orbOpacity`, 0.4–1.0, default 0.9), Reset orb position button.
- Orb size/opacity changes apply live to the visible orb.
Verification: manual — change size/opacity sliders and observe the orb; toggle launch-at-login and check System Settings → Login Items; press Reset and confirm orb returns to bottom-right 8 pt.

**US-25: As a user with ADHD, I want Focus settings for defaults and thresholds, so that presence sensitivity matches how I actually work.**
Acceptance criteria:
- Section contains: Default duration (`hf.defaultDurationMinutes`, 25), Default intensity (`hf.defaultIntensity`, `cinematic`), Warning threshold seconds (`hf.warningThresholdSeconds`, 7), Away threshold seconds (`hf.awayThresholdSeconds`, 15), Return recovery seconds (`hf.recoverySeconds`, 3), Allow sessions without camera (`hf.allowSessionsWithoutCamera`, true).
- Changed thresholds take effect for the next session (reducer reads them from `SettingsStore` at session start).
Verification: unit — reducer tests parameterized with non-default thresholds (e.g. warning 3 / away 5 / recovery 1) confirm transitions honor injected values; manual — set away threshold to 5, leave frame, away fires at ~5 s.

**US-26: As a user with ADHD, I want Camera settings with permission status and a privacy explanation, so that I understand and control the presence check.**
Acceptance criteria:
- Section contains: camera permission status (live from `CameraPermissionService`), Use camera for presence check (`hf.useCameraForPresence`, true), the privacy explanation, and a button opening System Settings camera permissions.
- Privacy text displayed exactly: `Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally on your Mac. Hyperfocus does not record, save, or upload camera footage.`
- With `hf.useCameraForPresence` off, sessions start in no-camera manual mode without prompting for permission.
Verification: manual — toggle the setting and start a session (no permission prompt, HUD `Camera off`); grep the built UI string against canon §9; verify the System Settings deep link opens.

**US-27: As a user with ADHD, I want Sound settings, so that voice and alarm match my sensory tolerance.**
Acceptance criteria:
- Section contains: Voice prompts on/off (`hf.voicePromptsEnabled`, true), Alarm sound on/off (`hf.alarmEnabled`, true), Volume slider (`hf.soundVolume`, 0.5), Voice style (`hf.voiceStyle`, `calm`; options calm/strict/cinematic with AVSpeech rate/pitch 0.45/1.0, 0.52/0.95, 0.42/0.85).
- With voice off: no spoken lines anywhere (countdown, away, restored, complete) — visuals unaffected.
- With alarm off: away mode shows red aura + card + voice line but plays no brown noise.
Verification: manual — disable voice, run full session (silent but visually complete); disable alarm, jump to away (no noise); move volume slider and confirm audible change in away state.

**US-28: As a user with ADHD, I want Visual settings including reduce motion, so that the cinematic layer never becomes a sensory problem.**
Acceptance criteria:
- Section contains: Aura intensity (`hf.auraIntensity`, 0.2–1.0, default 0.7), Aura thickness (`hf.auraThickness`, 0.5–1.5 multiplier on 120 pt, default 1.0), Reduce motion (`hf.reduceMotion`, false), Darken screen on start (`hf.darkenScreenOnStart`, true), Cinematic countdown on/off (`hf.cinematicCountdownEnabled`, true).
- With reduce motion on: countdown animations minimal, aura transitions instant, orb pulse static — all flows still functionally complete.
Verification: manual — sweep intensity/thickness sliders during an active session (live aura change); enable reduce motion and run a full session; disable darken-on-start and confirm countdown background stays lighter.

**US-29: As a user with ADHD, I want a Data section to view history and clear everything locally, so that my data stays mine.**
Acceptance criteria:
- Section contains: Session history (opens/embeds `HistoryView`) and Clear local data.
- Clear local data requires a confirmation, then `SessionStore.clear()` empties `sessions.json`; History shows empty afterward.
Verification: unit `SessionStoreTests.testClearRemovesAllSessions`; manual — save sessions, clear, confirm `sessions.json` is an empty array and History is empty.

---

## Onboarding & fallback

**US-30: As a user with ADHD, I want a short 5-screen onboarding on first launch, so that I understand the orb, the camera, and privacy before anything activates.**
Acceptance criteria:
- Shown only when `hf.onboardingCompleted` is false; on finishing, the flag is set true and onboarding never reappears.
- Exactly 5 screens with canon copy: (1) `Hyperfocus for Mac` / `A cinematic focus mode for one task at a time.` (2) `Enter focus mode` / `Click the orb, choose a mission, start the countdown.` (3) `Presence check` / `Hyperfocus can use your camera to pause the timer when you leave.` (4) `Private by default` / `Camera frames are processed locally. No recording. No upload.` (5) CTA `Start using Hyperfocus`.
- Onboarding itself never triggers a camera permission prompt.
- The privacy copy from canon §9 is presented in onboarding (screen 4 context) and in Settings → Camera.
Verification: manual — `defaults delete com.hyperfocus.app hf.onboardingCompleted`, relaunch, walk all 5 screens, relaunch again (no onboarding).

**US-31: As a user with ADHD, I want sessions to work without a camera, so that a denied permission or missing camera never blocks me from focusing.**
Acceptance criteria:
- If permission is denied, no camera exists, or `hf.useCameraForPresence` is off — and `hf.allowSessionsWithoutCamera` is true — the session starts in manual mode: timer runs, presence events never fire, only `.userPaused`/`.userResumed`/`.userExited` change the running state.
- HUD shows `Camera off`; no warning/away transitions occur; the persisted `Session` has `cameraEnabled == false`.
- If `hf.allowSessionsWithoutCamera` is false and the camera is unavailable, the start card explains why the session cannot start (no silent failure).
Verification: unit `SessionReducerTests.testNoCameraSession_ignoresPresenceThresholds` (ticks past 15 s with no face events → still `active`); manual — deny permission, run a full manual-pause/resume/complete session.

**US-32: As a user with ADHD, I want a hard guarantee that no video is ever recorded, saved, or uploaded, so that a camera-based focus app is safe to run all day.**
Acceptance criteria:
- Codebase contains no `AVCaptureMovieFileOutput`, no `AVAssetWriter`, no code writing `CVPixelBuffer`/`CGImage` to disk, and no network calls anywhere in the app (no URLSession usage for transfer; no network entitlements — App Sandbox enabled with only `com.apple.security.device.camera = true`).
- No identity recognition, no emotion detection — only `VNDetectFaceRectanglesRequest` (face rectangle presence).
- Camera session fully torn down on `stopCamera` (session ends, exit, abort); frames are processed in memory on `com.hyperfocus.camera` queue and discarded.
- Session storage contains only the `Session` fields from canon §7 — never image data.
Verification: code audit — `grep -rE "AVCaptureMovieFileOutput|AVAssetWriter|URLSession|VNClassify|VNRecognize" Hyperfocus/` returns no hits (URLSession absence check); inspect entitlements file; manual — run a session, then confirm nothing but `sessions.json` under `~/Library/Containers/com.hyperfocus.app/Data/Library/Application Support/Hyperfocus/` (App Sandbox container path) and camera LED off post-session.

---

## Debug simulation

**US-33: As a developer, I want a Debug menu that simulates presence without a camera, so that I can exercise and test the entire session flow deterministically.**
Acceptance criteria:
- Menu bar extra contains a `Debug` submenu compiled only in `DEBUG` builds, with exactly: `Simulate: Face Present` (emits `.facePresent`), `Simulate: Face Missing` (emits `.faceMissing`), `Simulate: Jump to Away` (emits `.faceMissing` and fast-forwards `faceMissingSeconds` to `awayThresholdSeconds`), `Simulate: Return` (emits `.facePresent`), `Use Simulated Camera` (toggle; swaps the `PresenceDetecting` implementation to `SimulatedPresenceService` for the next session).
- The simulated flow exercises everything with no camera: green aura → yellow warning → red away → alarm → recovery countdown → resume → completion.
- `SimulatedPresenceService` conforms to `PresenceDetecting` and delivers events on the main thread, identically to the real service.
- Release builds contain no Debug submenu.
Verification: manual — with `Use Simulated Camera` on, run the full scripted sequence above in one session; build Release configuration and confirm the submenu is absent; unit — reducer tests already cover the transitions the menu drives.

---

## Coverage matrix — BRIEF acceptance criteria 1–30

| # | BRIEF acceptance criterion | Covered by |
|---|---|---|
| 1 | I can launch the app on macOS | US-1 |
| 2 | A small Focus Orb appears on the screen | US-1 |
| 3 | I can drag the orb | US-2 |
| 4 | The orb saves its position | US-3 |
| 5 | Clicking the orb opens the start popover | US-5 |
| 6 | I can enter a mission | US-5 |
| 7 | I can choose a duration | US-6 |
| 8 | I cannot start without mission | US-7 |
| 9 | Clicking Enter Hyperfocus starts countdown | US-8 |
| 10 | The screen darkens during countdown | US-8 |
| 11 | The app says or displays "Enter Hyperfocus Mode. 3…2…1… Focus." | US-8 |
| 12 | After countdown, green edge glow appears | US-8, US-10 |
| 13 | Timer starts | US-8, US-11 |
| 14 | Camera permission is requested when needed | US-12 |
| 15 | If my face is visible, timer runs | US-13 |
| 16 | If my face is missing for 7 seconds, warning state starts | US-14 |
| 17 | If my face is missing for 15 seconds, away state starts | US-15 |
| 18 | In away state, timer pauses | US-15 |
| 19 | In away state, aura turns red | US-15 |
| 20 | In away state, alarm starts | US-15 |
| 21 | In away state, prompt says "Session paused. Return to Hyperfocus or exit." | US-15 |
| 22 | When I return for 3 seconds, alarm stops | US-16 |
| 23 | Aura becomes green again | US-16 |
| 24 | Timer resumes | US-16 |
| 25 | When timer ends, completion screen appears | US-19 |
| 26 | I can mark the result as Done, Partial or Not done | US-20 |
| 27 | Session stats are saved locally | US-20, US-23 |
| 28 | Camera stops after session ends | US-21 |
| 29 | Focus Orb returns to idle state | US-21 |
| 30 | No video is recorded, saved or uploaded | US-32 |

All 30 BRIEF criteria map to at least one story. Stories US-4 (quick actions), US-9 (countdown abort), US-17 (manual pause), US-18 (exit paths), US-22 (HUD), US-24–US-29 (settings), US-30 (onboarding), US-31 (no-camera fallback), and US-33 (debug simulation) cover canon-required behavior beyond the BRIEF's numbered list.

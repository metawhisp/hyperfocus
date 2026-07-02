// SessionReducerTests.swift — unit tests for the pure session state machine (canon §4–5).
// Names are the authoritative catalog from specs/06-testing.md §4 (D5).

import XCTest
@testable import Hyperfocus

final class SessionReducerTests: XCTestCase {

    // MARK: Helpers

    /// A context already in `.active` with a running 300 s camera session, face present.
    private func activeContext(
        planned: Int = 300,
        cameraEnabled: Bool = true,
        warning: Double = 7,
        away: Double = 15,
        recovery: Double = 3
    ) -> SessionContext {
        var ctx = SessionContext()
        ctx.state = .active
        ctx.config = SessionConfig(
            mission: "Write intro",
            successCondition: nil,
            plannedDurationSeconds: planned,
            intensity: .cinematic,
            cameraEnabled: cameraEnabled
        )
        ctx.remainingFocusTime = Double(planned)
        ctx.lastFacePresent = true
        ctx.cameraAvailable = cameraEnabled
        ctx.warningThresholdSeconds = warning
        ctx.awayThresholdSeconds = away
        ctx.recoverySeconds = recovery
        return ctx
    }

    private func validConfig(camera: Bool = true) -> SessionConfig {
        SessionConfig(mission: "Ship it", successCondition: nil,
                      plannedDurationSeconds: 300, intensity: .cinematic, cameraEnabled: camera)
    }

    /// Drives N whole-second ticks through the reducer, returning the effects of the final tick.
    @discardableResult
    private func tick(_ ctx: inout SessionContext, count: Int = 1, delta: Double = 1.0) -> [SessionEffect] {
        var last: [SessionEffect] = []
        for _ in 0..<count { last = SessionReducer.reduce(&ctx, .tick(deltaSeconds: delta)) }
        return last
    }

    // MARK: 4.1 Transition table

    func test_T1_idleToPreparing_emitsShowStartCard() {
        var ctx = SessionContext()
        let effects = SessionReducer.reduce(&ctx, .orbClicked)
        XCTAssertEqual(ctx.state, .preparing)
        XCTAssertEqual(effects, [.showStartCard])
    }

    func test_T2_preparingToIdle_onCancel_emitsHideStartCard() {
        var ctx = SessionContext(); ctx.state = .preparing
        let effects = SessionReducer.reduce(&ctx, .cancelPreparing)
        XCTAssertEqual(ctx.state, .idle)
        XCTAssertEqual(effects, [.hideStartCard])
    }

    func test_T3_preparingToCountdown_emitsCountdownVoiceAndCameraWarmup() {
        var ctx = SessionContext(); ctx.state = .preparing
        let effects = SessionReducer.reduce(&ctx, .enterHyperfocus(validConfig()))
        XCTAssertEqual(ctx.state, .countdown)
        XCTAssertTrue(effects.contains(.hideStartCard))
        XCTAssertTrue(effects.contains(.showCountdown))
        XCTAssertTrue(effects.contains(.playVoice(.countdown)))
        XCTAssertTrue(effects.contains(.startCameraWarmup))
        XCTAssertEqual(ctx.remainingFocusTime, 300)
    }

    func test_T3_preparing_rejectsEmptyMission_staysInPreparing() {
        var ctx = SessionContext(); ctx.state = .preparing
        let ws = SessionConfig(mission: "   \n\t ", successCondition: nil,
                               plannedDurationSeconds: 300, intensity: .calm, cameraEnabled: true)
        let effects = SessionReducer.reduce(&ctx, .enterHyperfocus(ws))
        XCTAssertEqual(ctx.state, .preparing)
        XCTAssertEqual(effects, [])
    }

    func test_T3_noCameraSession_omitsCameraWarmup() {
        var ctx = SessionContext(); ctx.state = .preparing
        let effects = SessionReducer.reduce(&ctx, .enterHyperfocus(validConfig(camera: false)))
        XCTAssertEqual(ctx.state, .countdown)
        XCTAssertFalse(effects.contains(.startCameraWarmup))
    }

    func test_T4_countdownToActive_startsTimerAuraPresence() {
        var ctx = SessionContext(); ctx.state = .countdown; ctx.config = validConfig()
        let effects = SessionReducer.reduce(&ctx, .countdownCompleted)
        XCTAssertEqual(ctx.state, .active)
        XCTAssertTrue(effects.contains(.dismissCountdown))
        XCTAssertTrue(effects.contains(.setAura(.green)))
        XCTAssertTrue(effects.contains(.startTimer))
        XCTAssertTrue(effects.contains(.startPresenceDetection))
    }

    func test_T4_noCameraSession_omitsPresenceDetection() {
        var ctx = SessionContext(); ctx.state = .countdown; ctx.config = validConfig(camera: false)
        let effects = SessionReducer.reduce(&ctx, .countdownCompleted)
        XCTAssertEqual(ctx.state, .active)
        XCTAssertFalse(effects.contains(.startPresenceDetection))
        XCTAssertTrue(effects.contains(.startTimer))
    }

    func test_T5_countdownToIdle_onExit_abortsWithoutSaving() {
        var ctx = SessionContext(); ctx.state = .countdown; ctx.config = validConfig()
        let effects = SessionReducer.reduce(&ctx, .userExited)
        XCTAssertEqual(ctx.state, .idle)
        XCTAssertTrue(effects.contains(.dismissCountdown))
        XCTAssertTrue(effects.contains(.stopCamera))
        XCTAssertFalse(effects.contains(where: { if case .saveSession = $0 { return true }; return false }))
    }

    func test_T6_activeToWarning_atThreshold_setsYellowAura() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 6)                       // faceMissing → 6, still active
        XCTAssertEqual(ctx.state, .active)
        let effects = tick(&ctx)                    // faceMissing → 7
        XCTAssertEqual(ctx.state, .warning)
        XCTAssertEqual(effects, [.setAura(.yellow)])
    }

    func test_T7_warningToActive_onFacePresent_noRecoveryDelay() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 7)                        // → warning
        XCTAssertEqual(ctx.state, .warning)
        let effects = SessionReducer.reduce(&ctx, .facePresenceChanged(true))
        XCTAssertEqual(ctx.state, .active)
        XCTAssertEqual(effects, [.setAura(.green)])
        XCTAssertEqual(ctx.faceMissingSeconds, 0)
    }

    func test_T8_warningToAway_pausesTimerStartsAlarmIncrementsBreakCount() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 14)                       // faceMissing → 14 (warning)
        XCTAssertEqual(ctx.state, .warning)
        let effects = tick(&ctx)                     // faceMissing → 15
        XCTAssertEqual(ctx.state, .away)
        XCTAssertTrue(effects.contains(.setAura(.red)))
        XCTAssertTrue(effects.contains(.pauseTimer))
        XCTAssertTrue(effects.contains(.startAlarm))
        XCTAssertTrue(effects.contains(.playVoice(.away)))
        XCTAssertTrue(effects.contains(.showAwayCard))
        XCTAssertEqual(ctx.breakCount, 1)
        XCTAssertEqual(ctx.currentStreakSeconds, 0)
    }

    func test_T9_activeToAway_onSimulateAway_sameEffectsAsT8() {
        var ctx = activeContext()
        // Debug fast-forward: face missing, faceMissingSeconds already at the away threshold.
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        ctx.faceMissingSeconds = ctx.awayThresholdSeconds
        let effects = tick(&ctx)
        XCTAssertEqual(ctx.state, .away)
        XCTAssertTrue(effects.contains(.setAura(.red)))
        XCTAssertTrue(effects.contains(.pauseTimer))
        XCTAssertTrue(effects.contains(.startAlarm))
        XCTAssertTrue(effects.contains(.playVoice(.away)))
        XCTAssertTrue(effects.contains(.showAwayCard))
        XCTAssertEqual(ctx.breakCount, 1)
    }

    func test_T10_awayToRecovering_onFacePresent_alarmKeepsPlaying() {
        var ctx = awayContext()
        let effects = SessionReducer.reduce(&ctx, .facePresenceChanged(true))
        XCTAssertEqual(ctx.state, .recovering)
        XCTAssertEqual(effects, [.showRecoveryCountdown])
        XCTAssertFalse(effects.contains(.stopAlarm))
    }

    func test_T11_recoveringToAway_onFaceLost_hidesRecoveryCountdown() {
        var ctx = awayContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))   // → recovering
        tick(&ctx, count: 2)                                          // recoveryElapsed → 2
        let effects = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        XCTAssertEqual(ctx.state, .away)
        XCTAssertEqual(effects, [.hideRecoveryCountdown])
        XCTAssertFalse(effects.contains(.stopAlarm))
        XCTAssertEqual(ctx.recoveryElapsed, 0)
    }

    func test_T12_recoveringToActive_afterRecoverySeconds_resumesEverything() {
        var ctx = awayContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))   // → recovering
        tick(&ctx, count: 2)                                          // recoveryElapsed → 2
        XCTAssertEqual(ctx.state, .recovering)
        let effects = tick(&ctx)                                       // recoveryElapsed → 3
        XCTAssertEqual(ctx.state, .active)
        XCTAssertTrue(effects.contains(.stopAlarm))
        XCTAssertTrue(effects.contains(.hideAwayCard))
        XCTAssertTrue(effects.contains(.hideRecoveryCountdown))
        XCTAssertTrue(effects.contains(.setAura(.green)))
        XCTAssertTrue(effects.contains(.resumeTimer))
        XCTAssertTrue(effects.contains(.playVoice(.restored)))
    }

    func test_T13_activeToManualPaused_pausesTimerDimsAura() {
        var ctx = activeContext()
        tick(&ctx, count: 10)                        // build a streak
        let effects = SessionReducer.reduce(&ctx, .userPaused)
        XCTAssertEqual(ctx.state, .manualPaused)
        XCTAssertEqual(effects, [.pauseTimer, .setAura(.dimmed)])
        XCTAssertEqual(ctx.breakCount, 0)
        XCTAssertEqual(ctx.currentStreakSeconds, 0)
    }

    func test_T14_manualPausedToActive_onResume_resumesTimerGreenAura() {
        var ctx = activeContext(); ctx.state = .manualPaused
        let effects = SessionReducer.reduce(&ctx, .userResumed)
        XCTAssertEqual(ctx.state, .active)
        XCTAssertEqual(effects, [.resumeTimer, .setAura(.green)])
    }

    func test_T15_activeToCompleted_atZeroRemaining_stopsAllPlaysCompleteShowsCompletion() {
        var ctx = activeContext(planned: 3)
        tick(&ctx, count: 2)
        XCTAssertEqual(ctx.state, .active)
        let effects = tick(&ctx)                     // remaining → 0
        XCTAssertEqual(ctx.state, .completed)
        XCTAssertTrue(effects.contains(.stopTimer))
        XCTAssertTrue(effects.contains(.stopCamera))
        XCTAssertTrue(effects.contains(.stopAlarm))
        XCTAssertTrue(effects.contains(.setAura(.flashThenHide)))
        XCTAssertTrue(effects.contains(.playVoice(.complete)))
        XCTAssertTrue(effects.contains(.showCompletion))
        XCTAssertEqual(ctx.remainingFocusTime, 0)
    }

    func test_T15_warningToCompleted_atZeroRemaining_sameAsFromActive() {
        var ctx = activeContext(planned: 10)
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 8)                         // → warning (faceMissing 8), remaining 2
        XCTAssertEqual(ctx.state, .warning)
        tick(&ctx)                                   // remaining 1
        let effects = tick(&ctx)                      // remaining 0 → completed (wins over away)
        XCTAssertEqual(ctx.state, .completed)
        XCTAssertTrue(effects.contains(.showCompletion))
    }

    func test_T16_activeToExitedToIdle_savesExitedSession() {
        var ctx = activeContext()
        let effects = SessionReducer.reduce(&ctx, .userExited)
        XCTAssertEqual(ctx.state, .idle)
        XCTAssertTrue(effects.contains(.stopTimer))
        XCTAssertTrue(effects.contains(.stopCamera))
        XCTAssertTrue(effects.contains(.stopAlarm))
        XCTAssertTrue(effects.contains(.setAura(.hidden)))
        XCTAssertTrue(effects.contains(.hideAwayCard))
        XCTAssertTrue(effects.contains(.saveSession(.exited)))
    }

    func test_T16_fromWarningAwayRecoveringManualPaused_userExited_allReachIdle() {
        for state: SessionState in [.warning, .away, .recovering, .manualPaused] {
            var ctx = activeContext()
            ctx.state = state
            let effects = SessionReducer.reduce(&ctx, .userExited)
            XCTAssertEqual(ctx.state, .idle, "exit from \(state)")
            XCTAssertTrue(effects.contains(.saveSession(.exited)), "exit from \(state)")
            XCTAssertTrue(effects.contains(.stopAlarm), "exit from \(state)")
        }
    }

    func test_T17_completedToIdle_onResultSaved_savesSessionAndFlashesOrb() {
        var ctx = activeContext(); ctx.state = .completed
        let effects = SessionReducer.reduce(&ctx, .resultSaved(.done, nextAction: "Write tests"))
        XCTAssertEqual(ctx.state, .idle)
        XCTAssertTrue(effects.contains(.saveSession(.done)))
        XCTAssertTrue(effects.contains(.hideCompletion))
        XCTAssertTrue(effects.contains(.orbFlash))
        XCTAssertEqual(ctx.nextAction, "Write tests")
    }

    func test_reducer_unhandledEvent_isNoOp() {
        // tick in idle
        var idle = SessionContext()
        XCTAssertEqual(SessionReducer.reduce(&idle, .tick(deltaSeconds: 1)), [])
        XCTAssertEqual(idle.state, .idle)
        // userResumed in active
        var active = activeContext()
        XCTAssertEqual(SessionReducer.reduce(&active, .userResumed), [])
        XCTAssertEqual(active.state, .active)
        // orbClicked in countdown
        var cd = SessionContext(); cd.state = .countdown
        XCTAssertEqual(SessionReducer.reduce(&cd, .orbClicked), [])
        XCTAssertEqual(cd.state, .countdown)
    }

    // MARK: 4.2 Counter arithmetic — worked example (specs/03 §4)

    func test_reducer_workedExample_finalCountersMatch() {
        var ctx = activeContext(planned: 300)

        // A: active for 60 ticks
        tick(&ctx, count: 60)
        XCTAssertEqual(ctx.remainingFocusTime, 240)
        XCTAssertEqual(ctx.activeFocusSeconds, 60)
        XCTAssertEqual(ctx.currentStreakSeconds, 60)
        XCTAssertEqual(ctx.longestStreakSeconds, 60)
        XCTAssertEqual(ctx.pausedSeconds, 0)
        XCTAssertEqual(ctx.breakCount, 0)

        // B: face lost, 15 ticks → away
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 15)
        XCTAssertEqual(ctx.state, .away)
        XCTAssertEqual(ctx.remainingFocusTime, 225)
        XCTAssertEqual(ctx.activeFocusSeconds, 75)      // warning ticks still count
        XCTAssertEqual(ctx.longestStreakSeconds, 75)
        XCTAssertEqual(ctx.currentStreakSeconds, 0)
        XCTAssertEqual(ctx.breakCount, 1)
        XCTAssertEqual(ctx.pausedSeconds, 0)

        // C: 20 ticks away, face returns, 3 ticks recovering → active
        tick(&ctx, count: 20)
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))
        tick(&ctx, count: 3)
        XCTAssertEqual(ctx.state, .active)
        XCTAssertEqual(ctx.pausedSeconds, 23)           // 20 away + 3 recovering
        XCTAssertEqual(ctx.remainingFocusTime, 225)
        XCTAssertEqual(ctx.activeFocusSeconds, 75)

        // D: 30 ticks active
        tick(&ctx, count: 30)
        XCTAssertEqual(ctx.activeFocusSeconds, 105)
        XCTAssertEqual(ctx.remainingFocusTime, 195)
        XCTAssertEqual(ctx.currentStreakSeconds, 30)
        XCTAssertEqual(ctx.longestStreakSeconds, 75)

        // E: manual pause, 10 ticks, resume
        _ = SessionReducer.reduce(&ctx, .userPaused)
        tick(&ctx, count: 10)
        _ = SessionReducer.reduce(&ctx, .userResumed)
        XCTAssertEqual(ctx.pausedSeconds, 33)
        XCTAssertEqual(ctx.currentStreakSeconds, 0)
        XCTAssertEqual(ctx.breakCount, 1)

        // F: 195 ticks → T15
        tick(&ctx, count: 195)
        XCTAssertEqual(ctx.state, .completed)
        XCTAssertEqual(ctx.activeFocusSeconds, 300)
        XCTAssertEqual(ctx.remainingFocusTime, 0)
        XCTAssertEqual(ctx.pausedSeconds, 33)
        XCTAssertEqual(ctx.breakCount, 1)
        XCTAssertEqual(ctx.longestStreakSeconds, 195)
    }

    func test_reducer_warningTicks_stillDecrementRemainingAndAccrueFocus() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 7)                         // → warning
        XCTAssertEqual(ctx.state, .warning)
        let remainingBefore = ctx.remainingFocusTime
        let focusBefore = ctx.activeFocusSeconds
        let streakBefore = ctx.currentStreakSeconds
        tick(&ctx)
        XCTAssertEqual(ctx.remainingFocusTime, remainingBefore - 1)
        XCTAssertEqual(ctx.activeFocusSeconds, focusBefore + 1)
        XCTAssertEqual(ctx.currentStreakSeconds, streakBefore + 1)
    }

    func test_reducer_awayRecoveringManualPausedTicks_accruePausedOnly() {
        // away
        var away = awayContext()
        var r = away.remainingFocusTime, f = away.activeFocusSeconds
        tick(&away)
        XCTAssertEqual(away.pausedSeconds, 1)
        XCTAssertEqual(away.remainingFocusTime, r); XCTAssertEqual(away.activeFocusSeconds, f)
        // manualPaused
        var mp = activeContext(); mp.state = .manualPaused
        r = mp.remainingFocusTime; f = mp.activeFocusSeconds
        tick(&mp)
        XCTAssertEqual(mp.pausedSeconds, 1)
        XCTAssertEqual(mp.remainingFocusTime, r); XCTAssertEqual(mp.activeFocusSeconds, f)
        // recovering
        var rec = awayContext()
        _ = SessionReducer.reduce(&rec, .facePresenceChanged(true))
        r = rec.remainingFocusTime; f = rec.activeFocusSeconds
        tick(&rec)                                    // recoveryElapsed 1 (< 3)
        XCTAssertEqual(rec.state, .recovering)
        XCTAssertEqual(rec.pausedSeconds, 1)
        XCTAssertEqual(rec.remainingFocusTime, r); XCTAssertEqual(rec.activeFocusSeconds, f)
    }

    func test_reducer_currentStreak_notResetOnWarning() {
        var ctx = activeContext()
        tick(&ctx, count: 3)                         // streak 3
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 7)                         // → warning, streak keeps growing
        XCTAssertEqual(ctx.state, .warning)
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))   // → active
        XCTAssertEqual(ctx.state, .active)
        // streak was never reset (only away/manualPaused reset it)
        XCTAssertEqual(ctx.currentStreakSeconds, 10)
    }

    func test_reducer_longestStreak_updatedEveryTick() {
        var ctx = activeContext()
        for i in 1...20 {
            tick(&ctx)
            XCTAssertEqual(ctx.longestStreakSeconds, Double(i))
            XCTAssertEqual(ctx.longestStreakSeconds, max(ctx.longestStreakSeconds, ctx.currentStreakSeconds))
        }
    }

    func test_reducer_breakCount_incrementsOncePerAwayEntry() {
        var ctx = awayContext()                       // breakCount already 1
        XCTAssertEqual(ctx.breakCount, 1)
        tick(&ctx, count: 5)                          // stay away → still 1
        XCTAssertEqual(ctx.breakCount, 1)
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))   // → recovering
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))  // → away again (T11)
        XCTAssertEqual(ctx.state, .away)
        // T11 does NOT re-increment; only a fresh away entry via threshold would
        XCTAssertEqual(ctx.breakCount, 1)
    }

    func test_reducer_sleepGap_excessCountsAsPaused() {
        var ctx = activeContext()
        let effects = SessionReducer.reduce(&ctx, .tick(deltaSeconds: 60.0))
        XCTAssertEqual(ctx.remainingFocusTime, 299)   // clamped to 1
        XCTAssertEqual(ctx.activeFocusSeconds, 1)
        XCTAssertEqual(ctx.pausedSeconds, 59)
        XCTAssertEqual(ctx.state, .active)
        XCTAssertEqual(effects, [])
    }

    func test_reducer_smallDeltaOverrun_clampedWithoutPausedCredit() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .tick(deltaSeconds: 3.0))    // ≤ 5 s stall
        XCTAssertEqual(ctx.remainingFocusTime, 299)
        XCTAssertEqual(ctx.activeFocusSeconds, 1)
        XCTAssertEqual(ctx.pausedSeconds, 0)
    }

    func test_reducer_noCameraSession_neverEntersWarningOrAway() {
        var ctx = activeContext(cameraEnabled: false)
        tick(&ctx, count: 100)
        XCTAssertEqual(ctx.state, .active)
        XCTAssertEqual(ctx.faceMissingSeconds, 0)
        // manual pause still works
        _ = SessionReducer.reduce(&ctx, .userPaused)
        XCTAssertEqual(ctx.state, .manualPaused)
    }

    func test_reducer_facePresentRaw_resetsFaceMissingSeconds() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 6)                          // faceMissing 6
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))
        XCTAssertEqual(ctx.faceMissingSeconds, 0)
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 6)                          // faceMissing 6 again
        XCTAssertEqual(ctx.state, .active)            // never reached 7
    }

    // MARK: 4.3 Debounce boundary cases

    // Boundary tests seed the counter and apply one 0.1 s tick to cross deterministically,
    // avoiding floating-point drift from summing 0.1 dozens of times (accrue-then-evaluate, §3).

    func test_reducer_faceMissing6_9s_staysActive() {
        var ctx = activeContext()
        ctx.lastFacePresent = false
        ctx.faceMissingSeconds = 6.8
        _ = SessionReducer.reduce(&ctx, .tick(deltaSeconds: 0.1))    // → ~6.9, still < 7
        XCTAssertEqual(ctx.faceMissingSeconds, 6.9, accuracy: 0.0001)
        XCTAssertEqual(ctx.state, .active)
    }

    func test_T6_activeToWarning_atExactly7_0s() {
        var ctx = activeContext()
        ctx.lastFacePresent = false
        ctx.faceMissingSeconds = 6.9
        let effects = SessionReducer.reduce(&ctx, .tick(deltaSeconds: 0.1))  // → 7.0
        XCTAssertEqual(ctx.state, .warning)
        XCTAssertEqual(effects, [.setAura(.yellow)])
    }

    func test_reducer_faceMissing14_9s_staysWarning() {
        var ctx = activeContext()
        ctx.state = .warning
        ctx.lastFacePresent = false
        ctx.faceMissingSeconds = 14.8
        _ = SessionReducer.reduce(&ctx, .tick(deltaSeconds: 0.1))    // → ~14.9, still < 15
        XCTAssertEqual(ctx.faceMissingSeconds, 14.9, accuracy: 0.0001)
        XCTAssertEqual(ctx.state, .warning)
    }

    func test_T8_warningToAway_atExactly15_0s() {
        var ctx = activeContext()
        ctx.state = .warning
        ctx.lastFacePresent = false
        ctx.faceMissingSeconds = 14.9
        let effects = SessionReducer.reduce(&ctx, .tick(deltaSeconds: 0.1))  // → 15.0
        XCTAssertEqual(ctx.state, .away)
        XCTAssertTrue(effects.contains(.startAlarm))
    }

    func test_reducer_recoveryInterruptedAt2_9s_returnsToAway() {
        var ctx = awayContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))   // → recovering
        ctx.recoveryElapsed = 2.9
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))  // interrupt → away
        XCTAssertEqual(ctx.state, .away)
        XCTAssertEqual(ctx.recoveryElapsed, 0)
        // next presence restarts recovery from 0
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))
        XCTAssertEqual(ctx.state, .recovering)
        XCTAssertEqual(ctx.recoveryElapsed, 0)
    }

    func test_reducer_recoveryCompletes_atExactly3_0s() {
        var ctx = awayContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))   // → recovering
        ctx.recoveryElapsed = 2.9
        _ = SessionReducer.reduce(&ctx, .tick(deltaSeconds: 0.1))     // → 3.0
        XCTAssertEqual(ctx.state, .active)
    }

    func test_reducer_thresholdsReadFromContext_notHardcoded() {
        var ctx = activeContext(warning: 5, away: 10, recovery: 2)
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 4); XCTAssertEqual(ctx.state, .active)     // < 5
        tick(&ctx); XCTAssertEqual(ctx.state, .warning)              // = 5
        tick(&ctx, count: 4); XCTAssertEqual(ctx.state, .warning)   // 9 < 10
        tick(&ctx); XCTAssertEqual(ctx.state, .away)                // = 10
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(true))  // → recovering
        tick(&ctx); XCTAssertEqual(ctx.state, .recovering)          // 1 < 2
        tick(&ctx); XCTAssertEqual(ctx.state, .active)              // = 2
    }

    // MARK: 4.7 Camera degradation (D1)

    func test_cameraLoss_activeStaysActiveTimerRuns() {
        var ctx = activeContext()
        let effects = SessionReducer.reduce(&ctx, .cameraStateChanged(.unavailable))
        XCTAssertEqual(ctx.state, .active)
        XCTAssertEqual(effects, [])
        XCTAssertFalse(ctx.cameraAvailable)
        // timer keeps running; presence transitions disabled forever after
        let before = ctx.remainingFocusTime
        tick(&ctx, count: 100)
        XCTAssertEqual(ctx.remainingFocusTime, before - 100)
        XCTAssertEqual(ctx.state, .active)
    }

    func test_cameraLoss_warningReturnsToActive() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 7)                          // → warning
        XCTAssertEqual(ctx.state, .warning)
        let effects = SessionReducer.reduce(&ctx, .cameraStateChanged(.disabled))
        XCTAssertEqual(ctx.state, .active)
        XCTAssertEqual(effects, [.setAura(.green)])
        XCTAssertEqual(ctx.faceMissingSeconds, 0)
    }

    func test_cameraLoss_awayEntersRecovering() {
        var ctx = awayContext()
        let effects = SessionReducer.reduce(&ctx, .cameraStateChanged(.notAuthorized))
        XCTAssertEqual(ctx.state, .recovering)
        XCTAssertEqual(effects, [.showRecoveryCountdown])
        // after recoverySeconds → active, alarm stops
        let resume = tick(&ctx, count: 3)
        XCTAssertEqual(ctx.state, .active)
        XCTAssertTrue(resume.contains(.stopAlarm))
        XCTAssertTrue(resume.contains(.resumeTimer))
    }

    // MARK: Corner cases (specs/03 §8)

    func test_cornerCase_userPausedInWarning_ignored() {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 7)
        XCTAssertEqual(ctx.state, .warning)
        let effects = SessionReducer.reduce(&ctx, .userPaused)
        XCTAssertEqual(effects, [])
        XCTAssertEqual(ctx.state, .warning)
    }

    func test_cornerCase_userExitedInIdle_ignored() {
        var ctx = SessionContext()
        XCTAssertEqual(SessionReducer.reduce(&ctx, .userExited), [])
        XCTAssertEqual(ctx.state, .idle)
        var prep = SessionContext(); prep.state = .preparing
        XCTAssertEqual(SessionReducer.reduce(&prep, .userExited), [])
        XCTAssertEqual(prep.state, .preparing)
    }

    func test_cornerCase_duplicateFacePresentTrue_idempotentNoEffects() {
        var ctx = activeContext()   // lastFacePresent already true
        let effects = SessionReducer.reduce(&ctx, .facePresenceChanged(true))
        XCTAssertEqual(effects, [])
        XCTAssertEqual(ctx.state, .active)
    }

    // MARK: Shared helper

    /// A context already in `.away` (breakCount 1, streak reset), camera session.
    private func awayContext() -> SessionContext {
        var ctx = activeContext()
        _ = SessionReducer.reduce(&ctx, .facePresenceChanged(false))
        tick(&ctx, count: 15)          // active → warning → away
        precondition(ctx.state == .away)
        return ctx
    }
}

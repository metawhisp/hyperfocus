// SessionReducer.swift — PURE synchronous state machine: (inout SessionContext, SessionEvent) -> [SessionEffect] (canon §4–5).
//
// This is the primary TDD surface. It never touches AppKit, AVFoundation, the file system, or the
// clock — all side effects are returned as [SessionEffect] for SessionCoordinator to execute, and
// wall/monotonic time enters only via SessionEvent.tick(deltaSeconds:). Effect order is significant:
// the reducer returns effects in the exact order the coordinator must apply them (specs/03 §3).

import Foundation

struct SessionReducer {

    static func reduce(_ ctx: inout SessionContext, _ event: SessionEvent) -> [SessionEffect] {
        switch event {
        case .orbClicked:
            return handleOrbClicked(&ctx)
        case .cancelPreparing:
            return handleCancelPreparing(&ctx)
        case .enterHyperfocus(let config):
            return handleEnterHyperfocus(&ctx, config)
        case .countdownCompleted:
            return handleCountdownCompleted(&ctx)
        case .tick(let delta):
            return handleTick(&ctx, delta)
        case .facePresenceChanged(let present):
            return handlePresence(&ctx, present: present)
        case .cameraStateChanged(let camState):
            return handleCameraState(&ctx, camState)
        case .userPaused:
            return handleUserPaused(&ctx)
        case .userResumed:
            return handleUserResumed(&ctx)
        case .userExited:
            return handleUserExited(&ctx)
        case .resultSaved(let status, let nextAction):
            return handleResultSaved(&ctx, status, nextAction)
        }
    }

    // MARK: Configuration transitions (T1–T5)

    private static func handleOrbClicked(_ ctx: inout SessionContext) -> [SessionEffect] {
        guard ctx.state == .idle else { return [] }          // T1
        ctx.state = .preparing
        return [.showStartCard]
    }

    private static func handleCancelPreparing(_ ctx: inout SessionContext) -> [SessionEffect] {
        guard ctx.state == .preparing else { return [] }     // T2
        ctx.state = .idle
        return [.hideStartCard]
    }

    private static func handleEnterHyperfocus(_ ctx: inout SessionContext, _ config: SessionConfig) -> [SessionEffect] {
        guard ctx.state == .preparing else { return [] }     // T3
        // Reducer guard: whitespace-only mission is treated as empty (UI also disables the CTA).
        guard !config.mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        startSession(&ctx, config: config)
        ctx.state = .countdown
        var effects: [SessionEffect] = [.hideStartCard, .showCountdown, .playVoice(.countdown)]
        if config.cameraEnabled { effects.append(.startCameraWarmup) }
        return effects
    }

    private static func handleCountdownCompleted(_ ctx: inout SessionContext) -> [SessionEffect] {
        guard ctx.state == .countdown else { return [] }     // T4
        ctx.state = .active
        var effects: [SessionEffect] = [.dismissCountdown, .setAura(.green), .startTimer]
        if ctx.config?.cameraEnabled == true { effects.append(.startPresenceDetection) }
        return effects
    }

    // MARK: Presence events (T7, T10, T11) + no-op presence in active/manualPaused

    private static func handlePresence(_ ctx: inout SessionContext, present: Bool) -> [SessionEffect] {
        switch ctx.state {
        case .active:
            ctx.lastFacePresent = present
            if present { ctx.faceMissingSeconds = 0 }         // idempotent; missing only starts accrual
            return []
        case .warning:
            if present {                                       // T7 — instant, no recovery delay
                ctx.lastFacePresent = true
                ctx.faceMissingSeconds = 0
                ctx.state = .active
                return [.setAura(.green)]
            }
            ctx.lastFacePresent = false
            return []
        case .away:
            if present {                                       // T10
                ctx.lastFacePresent = true
                ctx.recoveryElapsed = 0
                ctx.state = .recovering
                return [.showRecoveryCountdown]
            }
            ctx.lastFacePresent = false
            return []
        case .recovering:
            if present {                                       // duplicate present — keep recovering
                ctx.lastFacePresent = true
                return []
            }
            ctx.lastFacePresent = false                        // T11
            ctx.recoveryElapsed = 0
            ctx.state = .away
            return [.hideRecoveryCountdown]
        case .manualPaused:
            ctx.lastFacePresent = present                      // recorded, but changes nothing
            return []
        default:
            return []
        }
    }

    // MARK: Camera degradation mid-session (D1, canon §4 / specs/03 §5)

    private static func handleCameraState(_ ctx: inout SessionContext, _ camState: CameraState) -> [SessionEffect] {
        ctx.cameraState = camState
        let lost = camState == .notAuthorized || camState == .unavailable || camState == .disabled
        guard lost else {                                      // camera present / recovered
            ctx.cameraAvailable = true
            return []
        }
        ctx.cameraAvailable = false                            // presence can no longer be verified
        switch ctx.state {
        case .active:
            ctx.faceMissingSeconds = 0
            return []                                          // stay active; HUD shows "Camera off"
        case .warning:
            ctx.faceMissingSeconds = 0                         // T7 effect list back to active
            ctx.lastFacePresent = true
            ctx.state = .active
            return [.setAura(.green)]
        case .away:
            ctx.lastFacePresent = true                         // treat as face present → T10
            ctx.recoveryElapsed = 0
            ctx.state = .recovering
            return [.showRecoveryCountdown]
        case .recovering:
            ctx.lastFacePresent = true                         // recovery continues to completion
            return []
        default:
            return []
        }
    }

    // MARK: Manual pause / resume (T13, T14)

    private static func handleUserPaused(_ ctx: inout SessionContext) -> [SessionEffect] {
        guard ctx.state == .active else { return [] }         // T13 — active only (canon table)
        ctx.currentStreakSeconds = 0                          // breakCount NOT incremented
        ctx.state = .manualPaused
        return [.pauseTimer, .setAura(.dimmed)]
    }

    private static func handleUserResumed(_ ctx: inout SessionContext) -> [SessionEffect] {
        guard ctx.state == .manualPaused else { return [] }   // T14
        ctx.state = .active
        return [.resumeTimer, .setAura(.green)]
    }

    // MARK: Exit (T5 abort, T16 + T18)

    private static func handleUserExited(_ ctx: inout SessionContext) -> [SessionEffect] {
        switch ctx.state {
        case .countdown:                                       // T5 — abort, nothing saved
            ctx.state = .idle
            return [.dismissCountdown, .stopCamera]
        case .active, .warning, .away, .recovering, .manualPaused:
            // T16 → exited, then T18 fires immediately in the same reduce call (final state idle).
            ctx.state = .idle
            return [.stopTimer, .stopCamera, .stopAlarm, .setAura(.hidden), .hideAwayCard,
                    .saveSession(.exited)]
        default:
            return []                                          // idle / preparing / completed → ignored
        }
    }

    // MARK: Completion result (T17)

    private static func handleResultSaved(_ ctx: inout SessionContext, _ status: CompletionStatus, _ nextAction: String?) -> [SessionEffect] {
        guard ctx.state == .completed else { return [] }      // T17
        ctx.nextAction = nextAction                            // coordinator maps it onto the saved Session
        ctx.state = .idle
        return [.saveSession(status), .hideCompletion, .orbFlash]
    }

    // MARK: Tick pipeline (canon §4: clamp → accrue → evaluate)

    private static func handleTick(_ ctx: inout SessionContext, _ delta: Double) -> [SessionEffect] {
        switch ctx.state {
        case .active, .warning, .away, .recovering, .manualPaused: break
        default: return []                                     // idle/preparing/countdown/completed/exited
        }

        // 1. Clamp: a normal 1 Hz tick accrues ≤ 1 s; a >5 s gap (sleep/stall) dumps the excess to paused.
        let accrual = min(delta, Constants.Timing.maxTickDecrementSeconds)
        let sleepExcess = delta > Constants.Timing.sleepGapSeconds ? delta - accrual : 0

        // 2. Accrue by current state.
        switch ctx.state {
        case .active, .warning:
            ctx.remainingFocusTime = max(0, ctx.remainingFocusTime - accrual)
            ctx.activeFocusSeconds += accrual
            ctx.currentStreakSeconds += accrual
            ctx.longestStreakSeconds = max(ctx.longestStreakSeconds, ctx.currentStreakSeconds)
            if presenceMonitored(ctx) && !ctx.lastFacePresent { ctx.faceMissingSeconds += accrual }
            ctx.pausedSeconds += sleepExcess
        case .away, .manualPaused:
            ctx.pausedSeconds += accrual + sleepExcess
        case .recovering:
            ctx.pausedSeconds += accrual + sleepExcess
            if ctx.lastFacePresent { ctx.recoveryElapsed += accrual }
        default:
            break
        }

        // 3. Evaluate transitions, first match wins (T15 completion beats T8 away on the same tick).
        if (ctx.state == .active || ctx.state == .warning) && ctx.remainingFocusTime <= 0 {
            ctx.remainingFocusTime = 0
            ctx.state = .completed                             // T15
            return [.stopTimer, .stopCamera, .stopAlarm, .setAura(.flashThenHide),
                    .playVoice(.complete), .showCompletion]
        }
        if (ctx.state == .active || ctx.state == .warning),
           presenceMonitored(ctx), ctx.faceMissingSeconds >= ctx.awayThresholdSeconds {
            ctx.state = .away                                  // T8 (from warning) / T9 (from active)
            ctx.breakCount += 1
            ctx.currentStreakSeconds = 0
            return [.setAura(.red), .pauseTimer, .startAlarm, .playVoice(.away), .showAwayCard]
        }
        if ctx.state == .active,
           presenceMonitored(ctx), ctx.faceMissingSeconds >= ctx.warningThresholdSeconds {
            ctx.state = .warning                              // T6
            return [.setAura(.yellow)]
        }
        if ctx.state == .recovering,
           ctx.lastFacePresent, ctx.recoveryElapsed >= ctx.recoverySeconds {
            ctx.state = .active                               // T12
            ctx.faceMissingSeconds = 0
            ctx.recoveryElapsed = 0
            return [.stopAlarm, .hideAwayCard, .hideRecoveryCountdown, .setAura(.green),
                    .resumeTimer, .playVoice(.restored)]
        }
        return []
    }

    // MARK: Helpers

    /// Presence transitions are live only when the session uses the camera AND the camera is still
    /// available (canon §4 no-camera rule + camera-degradation rule D1).
    private static func presenceMonitored(_ ctx: SessionContext) -> Bool {
        (ctx.config?.cameraEnabled ?? false) && ctx.cameraAvailable
    }

    /// Resets all runtime counters for a fresh session at T3, preserving the coordinator-supplied
    /// thresholds. The coordinator stamps sessionStartTime/EndTime when it runs the timer effects.
    private static func startSession(_ ctx: inout SessionContext, config: SessionConfig) {
        ctx.config = config
        ctx.remainingFocusTime = Double(config.plannedDurationSeconds)
        ctx.activeFocusSeconds = 0
        ctx.pausedSeconds = 0
        ctx.breakCount = 0
        ctx.currentStreakSeconds = 0
        ctx.longestStreakSeconds = 0
        ctx.faceMissingSeconds = 0
        ctx.recoveryElapsed = 0
        ctx.lastFacePresent = true
        ctx.cameraAvailable = config.cameraEnabled
        ctx.cameraState = config.cameraEnabled ? .facePresent : .disabled
        ctx.nextAction = nil
        ctx.sessionStartTime = nil
        ctx.sessionEndTime = nil
    }
}

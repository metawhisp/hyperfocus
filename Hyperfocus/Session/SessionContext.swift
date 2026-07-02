// SessionContext.swift — mutable runtime data for the current session: state, config, and all timer/presence counters (canon §4).

import Foundation

struct SessionContext {
    var state: SessionState = .idle
    var config: SessionConfig?

    // Timer accounting (canon §4 "Timer accounting rules")
    var remainingFocusTime: Double = 0
    var activeFocusSeconds: Double = 0
    var pausedSeconds: Double = 0
    var breakCount: Int = 0
    var currentStreakSeconds: Double = 0
    var longestStreakSeconds: Double = 0

    // Presence tracking (canon §4 "Presence debouncing")
    var faceMissingSeconds: Double = 0
    var recoveryElapsed: Double = 0
    var lastFacePresent: Bool = true
    var cameraState: CameraState = .disabled
    // Camera availability for the running session (canon §4 "Camera degradation mid-session", D1).
    // false once the camera is lost mid-session; presence-driven transitions are then disabled.
    var cameraAvailable: Bool = true

    // Thresholds snapshotted at session start from SettingsStore (canon §8); the reducer reads
    // them from the context so they are user-tunable and unit-testable (never hard-coded).
    var warningThresholdSeconds: Double = Double(Constants.Timing.warningThresholdSeconds)
    var awayThresholdSeconds: Double = Double(Constants.Timing.awayThresholdSeconds)
    var recoverySeconds: Double = Double(Constants.Timing.recoverySeconds)

    // Result captured at T17 (canon §7 nextAction); the coordinator maps it onto the saved Session.
    var nextAction: String?

    // Session lifetime (the coordinator stamps these when it executes .startTimer / .saveSession,
    // keeping the reducer pure — no Date() inside reduce).
    var sessionStartTime: Date?
    var sessionEndTime: Date?
}

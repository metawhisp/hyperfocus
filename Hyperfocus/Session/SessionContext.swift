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

    // Session lifetime
    var sessionStartTime: Date?
    var sessionEndTime: Date?
}

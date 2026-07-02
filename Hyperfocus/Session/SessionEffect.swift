// SessionEffect.swift — side effects emitted by SessionReducer, plus VoiceLine / CameraState / VoiceStyle (canon §5–6).

import Foundation

enum SessionEffect: Equatable {
    case showStartCard, hideStartCard
    case showCountdown, dismissCountdown
    case setAura(AuraState)
    case startTimer, pauseTimer, resumeTimer, stopTimer
    case startCameraWarmup, startPresenceDetection, stopCamera
    case startAlarm, stopAlarm
    case playVoice(VoiceLine)
    case showAwayCard, hideAwayCard
    case showRecoveryCountdown, hideRecoveryCountdown
    case showCompletion, hideCompletion
    case saveSession(CompletionStatus)
    case orbFlash
}

enum VoiceLine { case countdown, away, restored, complete }

enum CameraState: Equatable {
    case notAuthorized, unavailable, disabled
    case facePresent, faceMissing
}

enum VoiceStyle: String, Codable, CaseIterable { case calm, strict, cinematic }

/// Which pre-recorded voice speaks the prompts (user-selectable in Settings; canon §13 #21).
enum VoicePersona: String, Codable, CaseIterable {
    case caspian, gideon
    var displayName: String { rawValue.capitalized }
}

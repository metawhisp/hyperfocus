// SessionEvent.swift — every input the session state machine reacts to (canon §5).

import Foundation

enum SessionEvent {
    case orbClicked
    case cancelPreparing
    case enterHyperfocus(SessionConfig)
    case countdownCompleted
    case tick(deltaSeconds: Double)
    case facePresenceChanged(Bool)     // raw, from PresenceDetecting
    case cameraStateChanged(CameraState)
    case userPaused
    case userResumed
    case userExited
    case resultSaved(CompletionStatus, nextAction: String?)
}

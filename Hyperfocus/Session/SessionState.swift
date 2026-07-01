// SessionState.swift — the locked session state machine states (canon §4).

import Foundation

enum SessionState: String, Codable {
    case idle, preparing, countdown, active, warning, away,
         recovering, manualPaused, completed, exited
}

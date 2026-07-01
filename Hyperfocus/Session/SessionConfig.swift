// SessionConfig.swift — user-chosen configuration for a single session (canon §2).

import Foundation

struct SessionConfig: Equatable {
    var mission: String
    var successCondition: String?
    var plannedDurationSeconds: Int
    var intensity: Intensity
    var cameraEnabled: Bool
}

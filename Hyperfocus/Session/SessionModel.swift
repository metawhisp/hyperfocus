// SessionModel.swift — the persisted Session record plus CompletionStatus and Intensity (canon §7).

import Foundation

struct Session: Codable, Identifiable, Equatable {
    let id: UUID
    var mission: String
    var successCondition: String?
    var plannedDurationSeconds: Int
    var activeFocusSeconds: Int
    var pausedSeconds: Int
    var breakCount: Int
    var longestStreakSeconds: Int
    var completionStatus: CompletionStatus
    var startedAt: Date
    var endedAt: Date?
    var intensity: Intensity
    var cameraEnabled: Bool
    var nextAction: String?          // flagged addition: completion screen has this field
}

enum CompletionStatus: String, Codable { case done, partial, notDone, exited }
enum Intensity: String, Codable, CaseIterable { case calm, strict, cinematic }

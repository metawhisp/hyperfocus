// PresenceDetecting.swift — contract for presence detection sources (real camera or simulated), plus PresenceEvent (canon §6).

import Foundation

protocol PresenceDetecting: AnyObject {
    var onEvent: ((PresenceEvent) -> Void)? { get set }  // delivered on main thread
    func startWarmup()          // pre-roll camera during countdown
    func startDetection()
    func stop()
}

enum PresenceEvent: Equatable {
    case facePresent
    case faceMissing
    case cameraState(CameraState)
}

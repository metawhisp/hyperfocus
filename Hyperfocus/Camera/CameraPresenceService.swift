// CameraPresenceService.swift — real presence detection: AVCaptureSession (640×480) + Vision face detection at 2 Hz (canon §6).

import Foundation

final class CameraPresenceService: PresenceDetecting {
    var onEvent: ((PresenceEvent) -> Void)?

    func startWarmup() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
    }

    func startDetection() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
    }

    func stop() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
    }
}

// CameraPermissionService.swift — camera authorization status and access request (canon §2).

import Foundation

final class CameraPermissionService {
    func currentCameraState() -> CameraState {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
        return .disabled
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
        completion(false)
    }
}

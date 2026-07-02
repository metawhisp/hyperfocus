// CameraPermissionService.swift — camera authorization status and access request (canon §2, §11).

import AVFoundation

final class CameraPermissionService {
    /// Maps the current TCC authorization to a CameraState (canon §6 camera states).
    func currentCameraState() -> CameraState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .facePresent      // authorized; presence resolved once capture starts
        case .notDetermined, .denied, .restricted: return .notAuthorized
        @unknown default: return .notAuthorized
        }
    }

    var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    /// Requests camera access, delivering the result on the main thread.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }
}

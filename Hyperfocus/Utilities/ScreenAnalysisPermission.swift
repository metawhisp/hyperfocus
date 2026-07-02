// ScreenAnalysisPermission.swift — Screen Recording (TCC) authorization for local screen analysis (canon §13 #23).
//
// Screen Recording has no entitlement; the system prompts on the first CGRequestScreenCaptureAccess()
// call. We only ever read this permission — no capture/recording happens here.

import CoreGraphics

final class ScreenAnalysisPermissionService {
    /// True if screen-recording access is already granted (no prompt).
    var isAuthorized: Bool { CGPreflightScreenCaptureAccess() }

    /// Triggers the system Screen Recording prompt (first time) and reports the result on the main thread.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        let granted = CGRequestScreenCaptureAccess()
        DispatchQueue.main.async { completion(granted) }
    }
}

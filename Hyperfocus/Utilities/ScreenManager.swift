// ScreenManager.swift — main-screen frame, visible bounds, and screen-parameter-change events (canon §3).

import AppKit

final class ScreenManager {
    /// Fired on NSApplication.didChangeScreenParametersNotification.
    var onScreenParametersChanged: (() -> Void)?

    func mainScreenFrame() -> CGRect {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 4
        return .zero
    }

    func visibleBounds() -> CGRect {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 4
        return .zero
    }

    func startObservingScreenChanges() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 4
    }
}

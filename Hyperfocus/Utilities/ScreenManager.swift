// ScreenManager.swift — main-screen frame, visible bounds, and screen-parameter-change events (canon §3).

import AppKit

final class ScreenManager {
    /// Fired on NSApplication.didChangeScreenParametersNotification.
    var onScreenParametersChanged: (() -> Void)?

    private var observer: NSObjectProtocol?

    /// Full frame of the main screen (includes menu bar area) — used for the aura windows.
    func mainScreenFrame() -> CGRect {
        NSScreen.main?.frame ?? .zero
    }

    /// Visible frame (excludes menu bar / Dock) — used to place and clamp the orb and cards.
    func visibleBounds() -> CGRect {
        NSScreen.main?.visibleFrame ?? .zero
    }

    func startObservingScreenChanges() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.onScreenParametersChanged?()
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }
}

// OverlayWindow.swift — factory for borderless, transparent, click-through overlay windows (canon §3).

import AppKit

enum OverlayWindow {
    /// A borderless, transparent, always-on-top window that never intercepts clicks or focus —
    /// used for the aura edge strips (canon §3 aura row).
    static func make(frame: CGRect) -> NSWindow {
        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isReleasedWhenClosed = false
        return window
    }
}

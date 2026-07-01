// OverlayWindow.swift — factory for borderless, transparent, click-through overlay windows (canon §3).

import AppKit

enum OverlayWindow {
    static func make(frame: CGRect) -> NSWindow {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 4
        return NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
    }
}

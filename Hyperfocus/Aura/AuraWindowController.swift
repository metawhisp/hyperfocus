// AuraWindowController.swift — owns the 4 edge overlay windows on the main screen (canon §3).

import AppKit
import SwiftUI

final class AuraWindowController {
    private let settings: SettingsStore
    private let screen: ScreenManager
    private let model = AuraModel()
    private var windows: [NSWindow] = []
    private var hideWorkItem: DispatchWorkItem?

    init(settings: SettingsStore, screen: ScreenManager) {
        self.settings = settings
        self.screen = screen
    }

    // MARK: State (canon §3 colors + intensity)

    func setState(_ state: AuraState) {
        hideWorkItem?.cancel()
        if windows.isEmpty { buildWindows() }
        model.reduceMotion = settings.reduceMotion

        // Faint by design (peripheral, "на 1%"): the living breathe/shimmer supplies presence, not brightness.
        let base = Constants.Aura.edgeMaxOpacity * settings.auraIntensity * 0.6
        switch state {
        case .hidden:
            model.visible = false
            scheduleTeardown()
        case .green:
            model.color = Palette.green; model.edgeOpacity = base; model.visible = true
        case .yellow:
            model.color = Palette.amber; model.edgeOpacity = base; model.visible = true
        case .red:
            model.color = Palette.red;   model.edgeOpacity = base; model.visible = true
        case .dimmed:
            model.color = Palette.green; model.edgeOpacity = base * 0.4; model.visible = true
        case .flashThenHide:
            model.color = Palette.green
            model.edgeOpacity = min(1.0, base * 1.6)
            model.visible = true
            let work = DispatchWorkItem { [weak self] in self?.setState(.hidden) }
            hideWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: work)
        }
    }

    /// Rebuild windows for the current main-screen geometry (canon §3.6 screen-change handling).
    func rebuildWindows() {
        let wasVisible = model.visible
        teardown()
        buildWindows()
        model.visible = wasVisible
    }

    // MARK: Windows

    private func buildWindows() {
        teardown()
        let frame = screen.mainScreenFrame()
        guard frame.width > 0 else { return }
        let thickness = Constants.Aura.baseThickness * settings.auraThickness

        // Left/right strips are inset vertically by `thickness` so they don't overlap the top/bottom
        // strips at the corners (overlap was double-drawing and darkening the corners).
        let sideHeight = max(0, frame.height - thickness * 2)
        let edges: [(AuraEdge, CGRect)] = [
            (.top,    CGRect(x: frame.minX, y: frame.maxY - thickness, width: frame.width, height: thickness)),
            (.bottom, CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: thickness)),
            (.left,   CGRect(x: frame.minX, y: frame.minY + thickness, width: thickness, height: sideHeight)),
            (.right,  CGRect(x: frame.maxX - thickness, y: frame.minY + thickness, width: thickness, height: sideHeight)),
        ]

        for (edge, rect) in edges {
            let window = OverlayWindow.make(frame: rect)
            let host = NSHostingView(rootView: AuraFrameView(model: model, edge: edge))
            host.frame = CGRect(origin: .zero, size: rect.size)
            host.autoresizingMask = [.width, .height]
            window.contentView = host
            window.orderFrontRegardless()          // never makeKey — aura must not steal focus (canon §3.3)
            windows.append(window)
        }
    }

    private func scheduleTeardown() {
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.model.visible == false else { return }
            self.teardown()
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    private func teardown() {
        for window in windows { window.orderOut(nil) }
        windows.removeAll()
    }
}

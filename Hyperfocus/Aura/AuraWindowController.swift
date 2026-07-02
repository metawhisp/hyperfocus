// AuraWindowController.swift — owns the single full-screen aura frame window (canon #28).

import AppKit
import SwiftUI

final class AuraWindowController {
    private let settings: SettingsStore
    private let screen: ScreenManager
    private let model = AuraModel()
    private var window: NSWindow?
    private var hideWorkItem: DispatchWorkItem?

    init(settings: SettingsStore, screen: ScreenManager) {
        self.settings = settings
        self.screen = screen
    }

    // MARK: State (canon §3 colors + intensity)

    func setState(_ state: AuraState) {
        hideWorkItem?.cancel()
        if window == nil { buildWindow() }
        model.reduceMotion = settings.reduceMotion
        model.thickness = settings.auraThickness

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

    /// Rebuild for the current main-screen geometry (canon §3.6 screen-change handling).
    func rebuildWindows() {
        let wasVisible = model.visible
        teardown()
        buildWindow()
        model.visible = wasVisible
    }

    // MARK: Window

    private func buildWindow() {
        teardown()
        let frame = screen.mainScreenFrame()
        guard frame.width > 0 else { return }
        let w = OverlayWindow.make(frame: frame)
        let host = NSHostingView(rootView: AuraFrameView(model: model))
        host.frame = CGRect(origin: .zero, size: frame.size)
        host.autoresizingMask = [.width, .height]
        w.contentView = host
        w.orderFrontRegardless()          // never makeKey — the aura must not steal focus (canon §3.3)
        window = w
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
        window?.orderOut(nil)
        window = nil
    }
}

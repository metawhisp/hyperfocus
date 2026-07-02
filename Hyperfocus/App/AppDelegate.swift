// AppDelegate.swift — window bootstrap and app lifecycle (canon §2).

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["HF_SNAPSHOT"] == "1" {
            DebugSnapshots.renderAll(app: AppState.shared)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { NSApp.terminate(nil) }
            return
        }
        #endif
        // Agent app (LSUIElement) — no Dock icon; the orb + menu bar extra are the UI.
        AppState.shared.bootstrap()
    }
}

// AppDelegate.swift — window bootstrap and app lifecycle (canon §2).

import AppKit
import CoreText

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        registerBundledFonts()   // segmented DSEG display font (must precede any UI, incl. snapshots)
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

    private func registerBundledFonts() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

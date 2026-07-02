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

        #if DEBUG
        // Automated input self-test: probe window-server hit-testing over the orb, log, and quit.
        if ProcessInfo.processInfo.environment["HF_SELFTEST"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                AppState.shared.runOrbHitSelfTest()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { NSApp.terminate(nil) }
            }
        }
        #endif
    }

    private func registerBundledFonts() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

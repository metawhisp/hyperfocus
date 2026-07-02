// AppDelegate.swift — window bootstrap and app lifecycle (canon §2).

import AppKit
import CoreText

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        registerBundledFonts()   // segmented DSEG display font (must precede any UI, incl. snapshots)
        #if DEBUG
        if ProcessInfo.processInfo.environment["HF_ORB_PREVIEW_LIVE"] == "1" {
            OrbLivePreviewWindow.show()   // animated design gallery; app stays alive until closed
            return
        }
        if ProcessInfo.processInfo.environment["HF_AURA_PREVIEW"] == "1" {
            AuraPreviewWindow.show()      // uniform-perimeter aura variants; user picks before prod
            return
        }
        if ProcessInfo.processInfo.environment["HF_SOUND_PREVIEW"] == "1" {
            SoundPreviewWindow.show()     // audition focus-sound candidates; user picks before prod
            return
        }
        if ProcessInfo.processInfo.environment["HF_COUNTDOWN_PREVIEW"] == "1" {
            CountdownPreviewWindow.show() // intro-frame variants; user picks before prod
            return
        }
        if ProcessInfo.processInfo.environment["HF_HUD_PREVIEW"] == "1" {
            HUDPreviewWindow.show()       // progress-bar variants; user picks before prod
            return
        }
        if ProcessInfo.processInfo.environment["HF_MINI_PREVIEW"] == "1" {
            MiniTimerPreviewWindow.show() // HUD collapse-to-orb demo; user approves before prod
            return
        }
        if ProcessInfo.processInfo.environment["HF_CAMERA_PREVIEW"] == "1" {
            CameraPitchPreviewWindow.show() // harder-selling ENABLE CAMERA variants
            return
        }
        if ProcessInfo.processInfo.environment["HF_READY_PREVIEW"] == "1" {
            ReadyCardPreviewWindow.show()   // READY? card — CUSTOM swaps in place
            return
        }
        if ProcessInfo.processInfo.environment["HF_DESIGN_PREVIEW"] == "1" {
            DesignPreviewRenderer.render()   // NEON VOID screen mockups → PNG
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
            return
        }
        if ProcessInfo.processInfo.environment["HF_ORB_PREVIEW"] == "1" {
            OrbPreviewRenderer.render()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
            return
        }
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

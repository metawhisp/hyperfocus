// HyperfocusApp.swift — @main entry point: MenuBarExtra scene and AppDelegate adaptor (canon §2, §10).

import SwiftUI

@main
struct HyperfocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Hyperfocus") {
            // Present only while the orb is hidden (specs/01 §11 item 1); visibility gating lands in Phase 2/10.
            Button("Show Focus Orb") {}
            Button("Settings…") {}
            Button("Session History…") {}
            #if DEBUG
            Divider()
            Menu("Debug") {
                Button("Simulate: Face Present") {}
                Button("Simulate: Face Missing") {}
                Button("Simulate: Jump to Away") {}
                Button("Simulate: Return") {}
                Toggle("Use Simulated Camera", isOn: .constant(false))
            }
            #endif
            Divider()
            // Must dispatch .userExited first if a session is running (specs/01 §11); wired in Phase 1.
            Button("Quit Hyperfocus") { NSApplication.shared.terminate(nil) }
        }
        .environmentObject(appState)
    }
}

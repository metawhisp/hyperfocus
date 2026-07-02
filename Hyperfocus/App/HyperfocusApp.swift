// HyperfocusApp.swift — @main entry point: MenuBarExtra scene and AppDelegate adaptor (canon §2, §10).

import SwiftUI

@main
struct HyperfocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra("Hyperfocus", systemImage: "circle.circle") {
            Button("Start Focus Session…") { appState.startSessionFromMenu() }
                .keyboardShortcut("n")
            Divider()
            Button("Show Focus Orb") { appState.showOrb() }
            Button("Settings…") { appState.showSettings() }
            Button("Session History…") { appState.showHistory() }

            #if DEBUG
            Divider()
            Menu("Debug") {
                Button("Simulate: Face Present") { appState.simulatePresent() }
                Button("Simulate: Face Missing") { appState.simulateMissing() }
                Button("Simulate: Jump to Away") { appState.simulateJumpToAway() }
                Button("Simulate: Return") { appState.simulateReturn() }
                Toggle("Use Simulated Camera", isOn: $appState.useSimulatedCamera)
            }
            #endif

            Divider()
            Button("Quit Hyperfocus") { appState.quit() }
        }
    }
}

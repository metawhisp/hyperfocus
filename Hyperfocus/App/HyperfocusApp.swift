// HyperfocusApp.swift — @main entry point: MenuBarExtra scene and AppDelegate adaptor (canon §2, §10).
// The menu uses the .window style so it can wear the FLIGHT DECK design (canon #38); the default
// .menu style is system-drawn and cannot be styled.

import SwiftUI
import AppKit

@main
struct HyperfocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra("Hyperfocus", systemImage: "circle.circle") {
            MenuBarContent(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Holds the menu's hosting window so an action can dismiss it (no re-render on set).
final class MenuWindowRef { weak var window: NSWindow? }

/// The FLIGHT DECK status-bar menu (canon #38): a dark device panel of styled rows with
/// hover highlight, replacing the system menu.
struct MenuBarContent: View {
    @ObservedObject var appState: AppState
    @State private var windowRef = MenuWindowRef()
    @State private var debugExpanded = false

    private func dismiss() { windowRef.window?.orderOut(nil) }
    private func run(_ action: () -> Void) { dismiss(); action() }

    var body: some View {
        VStack(spacing: 4) {
            header

            MenuRow(icon: "bolt.fill", title: "Start Focus Session", shortcut: "⌘N", accent: FD.lime) {
                run { appState.startSessionFromMenu() }
            }
            .keyboardShortcut("n", modifiers: .command)

            hairline
            MenuRow(icon: "circle.dotted", title: "Show Focus Orb") { run { appState.showOrb() } }
            MenuRow(icon: "gearshape.fill", title: "Settings") { run { appState.showSettings() } }
            MenuRow(icon: "clock.arrow.circlepath", title: "Session History") { run { appState.showHistory() } }

            #if DEBUG
            hairline
            MenuRow(icon: "ladybug.fill", title: "Debug", accent: FD.amber,
                    trailing: debugExpanded ? "chevron.up" : "chevron.down") {
                debugExpanded.toggle()
            }
            if debugExpanded {
                VStack(spacing: 2) {
                    MenuSubRow(title: "Simulate: Face Present") { run { appState.simulatePresent() } }
                    MenuSubRow(title: "Simulate: Face Missing") { run { appState.simulateMissing() } }
                    MenuSubRow(title: "Simulate: Jump to Away") { run { appState.simulateJumpToAway() } }
                    MenuSubRow(title: "Simulate: Return") { run { appState.simulateReturn() } }
                    Toggle("Use Simulated Camera", isOn: $appState.useSimulatedCamera)
                        .toggleStyle(.switch).tint(FD.lime)
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12).padding(.vertical, 5)
                }
                .padding(.leading, 14)
            }
            #endif

            hairline
            MenuRow(icon: "power", title: "Quit Hyperfocus", accent: FD.redLED) {
                run { appState.quit() }
            }
        }
        .padding(8)
        .frame(width: 268)
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
                Circle().fill(FD.lime.opacity(0.13)).frame(width: 150, height: 150)
                    .blur(radius: 55).offset(x: -30, y: -40)
            }
        )
        .background(WindowGrabber { windowRef.window = $0 })
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle().fill(FD.lime).frame(width: 7, height: 7)
                .shadow(color: FD.lime.opacity(0.9), radius: 4)
            Text("HYPERFOCUS").font(FD.matrix(13)).foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 6)
    }

    private var hairline: some View {
        Rectangle().fill(.white.opacity(0.07)).frame(height: 1).padding(.horizontal, 8).padding(.vertical, 3)
    }
}

/// A styled menu row: SF icon, title, optional shortcut/chevron, lime hover highlight.
private struct MenuRow: View {
    let icon: String
    let title: String
    var shortcut: String? = nil
    var accent: Color = FD.lime
    var trailing: String? = nil
    let action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(hover ? accent : .white.opacity(0.85))
                    .frame(width: 20)
                Text(title).font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(hover ? 1 : 0.88))
                Spacer(minLength: 8)
                if let shortcut {
                    Text(shortcut).font(.system(size: 12)).foregroundStyle(FD.label)
                }
                if let trailing {
                    Image(systemName: trailing).font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FD.label)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(hover ? accent.opacity(0.16) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(hover ? accent.opacity(0.35) : .clear, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

/// Indented sub-row for the Debug section (no icon).
private struct MenuSubRow: View {
    let title: String
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 12)).foregroundStyle(.white.opacity(hover ? 1 : 0.7))
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(hover ? FD.amber.opacity(0.14) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

/// Captures the hosting NSWindow so a menu action can dismiss the popover.
private struct WindowGrabber: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { onWindow(v.window) }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        if nsView.window != nil { onWindow(nsView.window) }
    }
}

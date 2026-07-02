// ExitConfirmView.swift — confirmation before leaving a running session (canon §13 #27).
// A stray click on the orb must never kill a hyperfocus session; the aura flashes red and the
// user explicitly chooses.

import SwiftUI

struct ExitConfirmView: View {
    var onStay: () -> Void
    var onExit: () -> Void

    var body: some View {
        GlassCard(width: 300) {
            VStack(spacing: 14) {
                Text("Exit Hyperfocus?")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.red)
                Text("Your session is still running.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button("Exit session", role: .destructive, action: onExit)
                        .buttonStyle(.bordered).tint(Palette.red)
                    Button("Stay focused", action: onStay)
                        .buttonStyle(.borderedProminent).tint(Palette.green)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
    }
}

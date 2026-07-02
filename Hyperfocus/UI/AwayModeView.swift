// AwayModeView.swift — "Session paused" glass card + recovery countdown, Return / Exit Session (canon §9).

import SwiftUI

struct AwayModeView: View {
    @EnvironmentObject var app: AppState
    var onReturn: () -> Void
    var onExit: () -> Void

    private var recovering: Bool { app.context.state == .recovering }

    var body: some View {
        GlassCard(width: 320) {
            VStack(spacing: 14) {
                if recovering {
                    // Recovery countdown shown within the away card (canon §9): 3 → 2 → 1 → Back to focus.
                    Text("Back to focus")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.green)
                    Text("Hold still…")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                } else {
                    Text(Constants.Copy.awayCardTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Palette.red)
                    Text(Constants.Copy.awayCardText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    Button(Constants.Copy.awayReturnButton, action: onReturn)
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.green)
                    Button(Constants.Copy.awayExitButton, action: onExit)
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

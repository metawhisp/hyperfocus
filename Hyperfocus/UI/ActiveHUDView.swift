// ActiveHUDView.swift — mission / remaining time / camera status / exit HUD shown during a session (canon §9).

import SwiftUI

struct ActiveHUDView: View {
    @EnvironmentObject var app: AppState
    var onExit: () -> Void

    private var ctx: SessionContext { app.context }

    var body: some View {
        GlassCard(width: 260) {
            VStack(alignment: .leading, spacing: 10) {
                Text(ctx.config?.mission ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)

                Text(mmss(Int(ctx.remainingFocusTime.rounded())))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                HStack(spacing: 7) {
                    Circle().fill(statusColor).frame(width: 8, height: 8)
                    Text(statusText).font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    Button("Exit", action: onExit)
                        .buttonStyle(.borderless)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.red)
                }
            }
        }
    }

    private var statusText: String {
        if ctx.config?.cameraEnabled != true || !ctx.cameraAvailable { return Constants.Copy.hudStatusCameraOff }
        switch ctx.state {
        case .active, .manualPaused, .recovering: return Constants.Copy.hudStatusPresent
        case .warning: return Constants.Copy.hudStatusLooking
        case .away: return Constants.Copy.hudStatusAway
        default: return Constants.Copy.hudStatusPresent
        }
    }

    private var statusColor: Color {
        switch ctx.state {
        case .warning: return Palette.amber
        case .away: return Palette.red
        default: return Palette.green
        }
    }
}

// ActiveHUDView.swift — mission / remaining time / exit HUD shown during a session (canon §9).
// FLIGHT DECK design (specs/07 v2): matrix countdown + mission centered, burning progress pill,
// quiet close button pinned to the card corner.

import SwiftUI

struct ActiveHUDView: View {
    @EnvironmentObject var app: AppState
    var onExit: () -> Void

    private var ctx: SessionContext { app.context }

    private var fraction: CGFloat {
        let planned = CGFloat(ctx.config?.plannedDurationSeconds ?? 0)
        guard planned > 0 else { return 0 }
        let f = 1 - CGFloat(ctx.remainingFocusTime) / planned
        return min(max(f, 0), 1)
    }

    var body: some View {
        let total = Int(ctx.remainingFocusTime.rounded())
        FDCard(width: 400) {
            VStack(spacing: 16) {
                // Countdown + mission — centered; the close button stays pinned to the corner.
                VStack(spacing: 6) {
                    MatrixTimer(mm: String(format: "%02d", total / 60),
                                ss: String(format: "%02d", total % 60),
                                size: 40, color: .white)
                    Text(ctx.config?.mission ?? "")
                        .font(.system(size: 13)).foregroundStyle(FD.label).lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                FDProgress(fraction: fraction, width: 352,
                           animated: !app.settings.reduceMotion)
            }
            .overlay(alignment: .topTrailing) {
                FDCloseButton { onExit() }
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// AwayModeView.swift — FLIGHT DECK away card: pulsing red PAUSED LED, Return / Exit Session (canon §9).

import SwiftUI

struct AwayModeView: View {
    @EnvironmentObject var app: AppState
    var onReturn: () -> Void
    var onExit: () -> Void

    var body: some View {
        FDCard(width: 340, glow: FD.redLED) {
            VStack(spacing: 12) {
                pausedTitle
                Text("RETURN TO HYPERFOCUS OR EXIT")
                    .font(.system(size: 11, weight: .bold)).tracking(1.2)
                    .foregroundStyle(FD.amber)
                HStack(spacing: 10) {
                    FDGhostButton(title: "Exit Session", destructive: true) { onExit() }
                    FDPrimaryButton(title: "RETURN") { onReturn() }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Slow red LED pulse; static when reduce-motion is on.
    @ViewBuilder
    private var pausedTitle: some View {
        if app.settings.reduceMotion {
            title
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                title.opacity(0.7 + 0.3 * abs(sin(t * 2)))
            }
        }
    }

    private var title: some View {
        Text("PAUSED")
            .font(FD.matrix(34))
            .foregroundStyle(FD.redLED)
            .shadow(color: FD.redLED.opacity(0.6), radius: 10)
    }
}

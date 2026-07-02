// ExitConfirmView.swift — confirmation before leaving a running session (canon §13 #27).
// FLIGHT DECK design (specs/07 v2): no pause exists — only STOP, and stopping counts as Not done.
// The red title and the card frame pulse live; static under reduce-motion.

import SwiftUI

struct ExitConfirmView: View {
    @EnvironmentObject var app: AppState
    var onStay: () -> Void
    var onExit: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0,
                                paused: app.settings.reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse: Double = app.settings.reduceMotion ? 1.0 : 0.55 + 0.45 * abs(sin(t * 3))
            FDCard(width: 360, glow: FD.redLED) {
                VStack(spacing: 14) {
                    Text("STOP HYPERFOCUS?")
                        .font(FD.matrix(26))
                        .foregroundStyle(FD.redLED)
                        .shadow(color: FD.redLED.opacity(0.7), radius: 12)
                        .opacity(pulse)
                    HStack(spacing: 8) {
                        PixelIcon(pattern: PixelIcon.skull, color: FD.redLED)
                        Text("STOPPING COUNTS AS NOT DONE")
                            .font(.system(size: 11, weight: .bold)).tracking(1)
                            .foregroundStyle(FD.amber)
                    }
                    HStack(spacing: 10) {
                        FDGhostButton(title: "Stop", destructive: true) { onExit() }
                        FDPrimaryButton(title: "KEEP GOING") { onStay() }
                            .keyboardShortcut(.defaultAction)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(FD.redLED.opacity(0.6), lineWidth: 1.5)
                    .opacity(pulse)
            )
        }
    }
}

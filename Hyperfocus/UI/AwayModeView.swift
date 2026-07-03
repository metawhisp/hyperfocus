// AwayModeView.swift — FLIGHT DECK away card with the exit TRAP (canon §9, #40):
// hovering EXIT SESSION already proves the user is back at the screen, so it kicks recovery;
// clicking it opens ARE YOU SURE? whose primary action is RETURN — by the time the user reads
// it, the session has resumed by itself. The exit becomes a springboard back into focus.

import SwiftUI

struct AwayModeView: View {
    @EnvironmentObject var app: AppState
    var onReturn: () -> Void
    var onExit: () -> Void

    @State private var sure = false
    @State private var kicked = false

    var body: some View {
        FDCard(width: 340, glow: sure ? FD.amber : FD.redLED) {
            if sure { sureCard } else { awayCard }
        }
        .animation(.easeInOut(duration: 0.2), value: sure)
    }

    // MARK: Phase 1 — PAUSED

    private var awayCard: some View {
        VStack(spacing: 12) {
            pausedTitle
            Text("RETURN TO HYPERFOCUS OR EXIT")
                .font(.system(size: 11, weight: .bold)).tracking(1.2)
                .foregroundStyle(FD.amber)
            if kicked {
                Label("Camera sees you — resuming…", systemImage: "eye.fill")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(FD.lime)
            }
            HStack(spacing: 10) {
                FDGhostButton(title: "Exit Session", destructive: true) { sure = true }
                    .onHover { hovering in
                        // Reaching for the exit = being back at the screen = recovery starts.
                        if hovering && !kicked {
                            kicked = true
                            onReturn()
                        }
                    }
                FDPrimaryButton(title: "RETURN") { onReturn() }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Phase 2 — ARE YOU SURE? (recovery is already running underneath)

    private var sureCard: some View {
        VStack(spacing: 12) {
            Text("ARE YOU SURE?")
                .font(FD.matrix(26))
                .foregroundStyle(FD.amber)
                .shadow(color: FD.amber.opacity(0.6), radius: 10)
            Text("You're already back at the screen —\nthe session is resuming right now.")
                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            FDPrimaryButton(title: "RETURN TO HYPERFOCUS", fullWidth: true) { onReturn() }
            Button("Exit anyway") { onExit() }
                .buttonStyle(.plain)
                .font(.system(size: 10))
                .foregroundStyle(FD.label)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            // Clicking EXIT is itself presence — make sure recovery is running.
            if !kicked { kicked = true }
            onReturn()
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

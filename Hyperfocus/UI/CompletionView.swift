// CompletionView.swift — FLIGHT DECK completion card: focus time, fresh achievement, badge row,
// mission question → Done / Partial / Not done (canon §9, #29).

import SwiftUI

struct CompletionView: View {
    @EnvironmentObject var app: AppState
    let unlocks: [Achievement]                 // fresh unlocks for this session
    var onResult: (CompletionStatus) -> Void

    private var focusSeconds: Int { Int(app.context.activeFocusSeconds.rounded()) }

    var body: some View {
        FDCard(width: 380) {
            VStack(spacing: 14) {
                Text("HYPERFOCUS COMPLETE")
                    .font(.system(size: 11, weight: .bold)).tracking(2)
                    .foregroundStyle(FD.amber)

                MatrixTimer(mm: String(format: "%02d", focusSeconds / 60),
                            ss: String(format: "%02d", focusSeconds % 60),
                            size: 44, color: FD.lime)
                    .shadow(color: FD.lime.opacity(0.7), radius: 14)
                Text("FOCUS TIME").font(.system(size: 10, weight: .semibold)).tracking(1.5)
                    .foregroundStyle(FD.label)

                // Freshly unlocked achievement — the reward moment.
                if let first = unlocks.first {
                    FDInset {
                        HStack(spacing: 10) {
                            PixelIcon(pattern: PixelIcon.pattern(named: first.icon), color: FD.lime)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("NEW ACHIEVEMENT")
                                    .font(.system(size: 8, weight: .bold)).tracking(1.5)
                                    .foregroundStyle(FD.label)
                                Text("\(first.title) — \(first.detail)")
                                    .font(.system(size: 12, weight: .bold)).foregroundStyle(FD.lime)
                            }
                        }
                    }
                }

                // Earned badges line up in a row.
                HStack(spacing: 6) {
                    FDBadge(icon: PixelIcon.flame,
                            label: "×\(app.achievements.dayStreak(history: app.store.all()))",
                            color: FD.amber)
                    ForEach(app.achievements.recentBadges(limit: 2)) { badge in
                        FDBadge(icon: PixelIcon.pattern(named: badge.icon),
                                label: badge.title, color: FD.lime)
                    }
                }

                // The timer is done — but did the MISSION get done? We can't know; ask.
                Text("Did you complete the mission?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))

                HStack(spacing: 8) {
                    FDPrimaryButton(title: "DONE") { onResult(.done) }
                    Button { onResult(.partial) } label: {
                        Text("Partial")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(FD.amber)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Capsule().fill(FD.amber.opacity(0.12)))
                    }
                    .buttonStyle(HFPressStyle())
                    FDGhostButton(title: "Not done", destructive: true) { onResult(.notDone) }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

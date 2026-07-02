// HistoryView.swift — simple list of recent sessions: Date / Mission / Duration / Status / Breaks (BRIEF).

import SwiftUI

struct HistoryView: View {
    let sessions: [Session]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SESSION HISTORY")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(FD.label)
                .padding(16)

            if sessions.isEmpty {
                Spacer()
                Text("No sessions yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(FD.label)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List(sessions.reversed()) { s in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(s.mission)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer()
                            Text(statusLabel(s.completionStatus))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(statusColor(s.completionStatus))
                        }
                        HStack(spacing: 8) {
                            Text(Self.dateFormatter.string(from: s.startedAt))
                                .font(.system(size: 11))
                                .foregroundStyle(FD.label)
                            Text(mmss(s.activeFocusSeconds))
                                .font(FD.matrix(12))
                                .foregroundStyle(.white.opacity(0.70))
                            Text("focus · \(s.breakCount) breaks")
                                .font(.system(size: 11))
                                .foregroundStyle(FD.label)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.white.opacity(0.07))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 420, height: 460)
        .background(Color(red: 0.06, green: 0.065, blue: 0.075))
        .preferredColorScheme(.dark)
    }

    private func statusLabel(_ s: CompletionStatus) -> String {
        switch s {
        case .done: return "Done"
        case .partial: return "Partial"
        case .notDone, .exited: return "Not done"   // early exits count as Not done (canon #29)
        }
    }

    private func statusColor(_ s: CompletionStatus) -> Color {
        switch s {
        case .done: return FD.lime
        case .partial: return FD.amber
        case .notDone, .exited: return FD.redLED
        }
    }
}

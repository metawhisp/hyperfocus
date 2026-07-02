// HistoryView.swift — simple list of recent sessions: Date / Mission / Duration / Status / Breaks (BRIEF).

import SwiftUI

struct HistoryView: View {
    let sessions: [Session]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Session History")
                .font(.system(size: 15, weight: .semibold))
                .padding(16)

            if sessions.isEmpty {
                Spacer()
                Text("No sessions yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List(sessions.reversed()) { s in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(s.mission).font(.system(size: 13, weight: .medium)).lineLimit(1)
                            Spacer()
                            Text(statusLabel(s.completionStatus))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(statusColor(s.completionStatus))
                        }
                        HStack(spacing: 10) {
                            Text(Self.dateFormatter.string(from: s.startedAt))
                            Text("· \(mmss(s.activeFocusSeconds)) focus")
                            Text("· \(s.breakCount) breaks")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .frame(width: 420, height: 460)
    }

    private func statusLabel(_ s: CompletionStatus) -> String {
        switch s {
        case .done: return "Done"
        case .partial: return "Partial"
        case .notDone: return "Not done"
        case .exited: return "Exited"
        }
    }

    private func statusColor(_ s: CompletionStatus) -> Color {
        switch s {
        case .done: return Palette.green
        case .partial: return Palette.amber
        case .notDone, .exited: return Palette.red
        }
    }
}

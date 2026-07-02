// CompletionView.swift — "Mission complete" card: stats, Done / Partial / Not done, next action (canon §9).

import SwiftUI

struct CompletionView: View {
    @EnvironmentObject var app: AppState
    var onResult: (CompletionStatus, String?) -> Void

    @State private var nextAction = ""

    private var ctx: SessionContext { app.context }

    var body: some View {
        GlassCard(width: 340) {
            VStack(alignment: .leading, spacing: 16) {
                Text(Constants.Copy.completionTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.green)

                VStack(spacing: 8) {
                    statRow("Mission", ctx.config?.mission ?? "—")
                    statRow("Focus time", mmss(Int(ctx.activeFocusSeconds.rounded())))
                    statRow("Paused time", mmss(Int(ctx.pausedSeconds.rounded())))
                    statRow("Breaks", "\(ctx.breakCount)")
                    statRow("Longest streak", mmss(Int(ctx.longestStreakSeconds.rounded())))
                }

                Text(Constants.Copy.completionQuestion)
                    .font(.system(size: 13, weight: .medium))

                HStack(spacing: 8) {
                    resultButton(Constants.Copy.completionDoneButton, .done, Palette.green)
                    resultButton(Constants.Copy.completionPartialButton, .partial, Palette.amber)
                    resultButton(Constants.Copy.completionNotDoneButton, .notDone, Palette.red)
                }

                TextField(Constants.Copy.nextActionPlaceholder, text: $nextAction)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.1)))
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium)).lineLimit(1)
        }
    }

    private func resultButton(_ title: String, _ status: CompletionStatus, _ tint: Color) -> some View {
        Button(title) {
            let trimmed = nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
            onResult(status, trimmed.isEmpty ? nil : trimmed)
        }
        .buttonStyle(.bordered)
        .tint(tint)
        .frame(maxWidth: .infinity)
    }
}

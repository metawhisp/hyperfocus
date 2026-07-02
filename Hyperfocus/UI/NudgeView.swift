// NudgeView.swift — gentle, non-shaming banner shown when screen analysis spots a distraction (canon §9 tone).

import SwiftUI

struct NudgeView: View {
    let mission: String

    var body: some View {
        GlassCard(width: 300) {
            HStack(spacing: 12) {
                Circle().fill(Palette.amber).frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Still on it?")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Back to: \(mission)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

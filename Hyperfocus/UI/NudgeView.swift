// NudgeView.swift — gentle, non-shaming banner shown when screen analysis spots a distraction (canon §9 tone).

import SwiftUI

struct NudgeView: View {
    let mission: String

    var body: some View {
        FDCard(width: 300, glow: FD.amber) {
            HStack(spacing: 12) {
                PixelIcon(pattern: PixelIcon.bolt, color: FD.amber)
                VStack(alignment: .leading, spacing: 3) {
                    Text("STILL ON IT?")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(FD.amber)
                    Text("Back to: \(mission)")
                        .font(.system(size: 12))
                        .foregroundStyle(FD.label)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

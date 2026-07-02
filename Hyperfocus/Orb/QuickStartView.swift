// QuickStartView.swift — long-press quick-start chips: recent session durations around the orb (canon §13 #25).
//
// Shown while the mouse button is still held after a long-press on the orb. The user drags onto a
// chip and releases to start immediately. Highlight is driven externally (hover tracking does not
// fire during a drag, so the coordinator feeds pointer positions into QuickStartModel).

import SwiftUI

final class QuickStartModel: ObservableObject {
    @Published var highlighted: Int?
}

struct QuickStartChipView: View {
    let minutes: Int
    let index: Int
    @ObservedObject var model: QuickStartModel
    @State private var appeared = false

    var body: some View {
        let hot = model.highlighted == index
        Text("\(minutes) min")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(hot ? .black : .white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(hot ? AnyShapeStyle(Palette.green) : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(hot ? 0 : 0.25), lineWidth: 0.75))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            .scaleEffect(hot ? 1.12 : (appeared ? 1.0 : 0.7))
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: hot)
            .onAppear {
                withAnimation(.easeOut(duration: 0.22).delay(Double(index) * 0.05)) { appeared = true }
            }
            .preferredColorScheme(.dark)
    }
}

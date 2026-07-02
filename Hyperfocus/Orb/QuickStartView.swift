// QuickStartView.swift — long-press quick-start chips: recent session durations around the orb (canon §13 #25).
//
// Shown while the mouse button is still held after a long-press on the orb. The user drags onto a
// chip and releases to start immediately. Highlight is driven externally (hover tracking does not
// fire during a drag, so the coordinator feeds pointer positions into QuickStartModel).

import SwiftUI

final class QuickStartModel: ObservableObject {
    @Published var highlighted: Int?
}

// Gallery-picked design E "GHOST NUMBERS" (canon #34): no containers — big glowing matrix
// digits materialize out of a blur; the one under the drag turns lime, grows and gets an
// underline tick. A dark text shadow keeps the digits readable over light desktops.
struct QuickStartChipView: View {
    let minutes: Int
    let index: Int
    @ObservedObject var model: QuickStartModel
    @State private var appeared = false

    var body: some View {
        let hot = model.highlighted == index
        VStack(spacing: 3) {
            // fixedSize: the panel is sized from fittingSize, which can under-measure intrinsic
            // text by a few points — the digits then truncate to "…" (the old "15…" bug).
            Text("\(minutes)")
                .font(FD.matrix(26))
                .fixedSize()
                .foregroundStyle(hot ? FD.lime : .white.opacity(0.92))
                .shadow(color: .black.opacity(0.75), radius: 3, y: 1)
                .shadow(color: FD.lime.opacity(hot ? 1.0 : 0.35), radius: hot ? 18 : 8)
            Text("MIN")
                .font(.system(size: 8, weight: .bold)).tracking(1.6)
                .fixedSize()
                .foregroundStyle(.white.opacity(0.6))
                .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
            Rectangle().fill(FD.lime)
                .frame(width: hot ? 34 : 0, height: 2)
                .shadow(color: FD.lime.opacity(0.9), radius: 4)
        }
        .scaleEffect((hot ? 1.15 : 1) * (appeared ? 1 : 0.6))
        .blur(radius: appeared ? 0 : 6)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: hot)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35).delay(Double(index) * 0.12)) { appeared = true }
        }
        .preferredColorScheme(.dark)
    }
}

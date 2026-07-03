// AuraFrameView.swift — uniform perimeter aura frame (canon #28, user-picked design A1 "ровная рамка").
//
// ONE closed stroke around the whole screen — even glow along the entire perimeter, corners
// included (the old 4-strip construction left corner gaps). Near-steady gentle breathe; static
// under reduce-motion; render loop paused while hidden.

import SwiftUI

/// Shared observable driving the aura window.
final class AuraModel: ObservableObject {
    @Published var color: Color = Palette.green
    @Published var visible = false
    @Published var edgeOpacity: Double = 0.24     // base alpha (kept faint; the stroke concentrates it)
    @Published var thickness: Double = 1.0        // hf.auraThickness multiplier
    @Published var reduceMotion = false
    /// Alert emphasis (exit confirmation): widens the band and blur, pushes alpha up.
    @Published var boost: Double = 1.0
    /// Away ramp (canon #40): when set, the red frame swells ×3.5 over its first 7 seconds.
    @Published var rampStart: Date?
}

struct AuraFrameView: View {
    @ObservedObject var model: AuraModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0,
                                paused: !model.visible || model.reduceMotion)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let breathe = model.reduceMotion ? 1.0 : 0.92 + 0.08 * sin(t * 0.7)   // A1: near-steady
            // Away ramp: the red frame swells ×3.5 over its first 7 s — leaving must be
            // impossible to ignore, but it builds instead of slamming.
            let ramp: Double = {
                guard let start = model.rampStart else { return 1 }
                return 1.0 + 2.5 * min(1, tl.date.timeIntervalSince(start) / 7.0)
            }()
            let line = 12.0 * model.thickness * model.boost * min(ramp, 2.2)
            // The stroke concentrates light into a thin band, so it can run brighter than the old
            // wide gradient at the same setting (capped at 1).
            let alpha = min(1.0, model.edgeOpacity * 3.0 * model.boost * ramp) * breathe
            Rectangle()
                .strokeBorder(model.color, lineWidth: line)
                .blur(radius: 18 * model.thickness * model.boost * min(ramp, 2.2))
                .opacity(alpha)
        }
        .opacity(model.visible ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: model.visible)
        .animation(.easeInOut(duration: 0.5), value: model.color)
        .animation(.easeInOut(duration: 0.35), value: model.boost)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// AuraFrameView.swift — living gradient glow per screen edge, driven by a shared AuraModel (canon §3).
//
// The glow breathes slowly and shimmers subtly so it feels alive without being distracting; it is
// deliberately faint (peripheral, never neon). Reduce-motion renders it static.

import SwiftUI

enum AuraEdge { case top, bottom, left, right }

/// Shared observable driving all four edge windows so they animate in lockstep.
final class AuraModel: ObservableObject {
    @Published var color: Color = Palette.green
    @Published var visible = false
    @Published var edgeOpacity: Double = 0.24     // peak alpha at the very edge (kept faint)
    @Published var reduceMotion = false
}

struct AuraFrameView: View {
    @ObservedObject var model: AuraModel
    let edge: AuraEdge

    var body: some View {
        Group {
            if model.reduceMotion {
                gradient(breath: 1.0, shimmer: 0.5)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    // Slow breathe (~8 s) + faster shimmer (~3.7 s), phase-offset per edge so the
                    // frame gently "переливается" around the screen rather than pulsing as one block.
                    let breath = 0.72 + 0.28 * (0.5 + 0.5 * sin(t * 0.8 + phaseOffset))
                    let shimmer = 0.5 + 0.5 * sin(t * 1.7 + phaseOffset * 2)
                    gradient(breath: breath, shimmer: shimmer)
                }
            }
        }
        .opacity(model.visible ? model.edgeOpacity : 0)
        .animation(.easeInOut(duration: 0.5), value: model.visible)
        .animation(.easeInOut(duration: 0.5), value: model.color)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var phaseOffset: Double {
        switch edge {
        case .top: return 0
        case .right: return 1.6
        case .bottom: return 3.1
        case .left: return 4.7
        }
    }

    private func gradient(breath: Double, shimmer: Double) -> LinearGradient {
        let lit = model.color.opacity(breath)
        let mid = model.color.opacity(breath * (0.30 + 0.22 * shimmer))
        let (start, end): (UnitPoint, UnitPoint)
        switch edge {
        case .top:    (start, end) = (.top, .bottom)
        case .bottom: (start, end) = (.bottom, .top)
        case .left:   (start, end) = (.leading, .trailing)
        case .right:  (start, end) = (.trailing, .leading)
        }
        return LinearGradient(stops: [
            .init(color: lit, location: 0.0),
            .init(color: mid, location: 0.45),
            .init(color: .clear, location: 1.0),
        ], startPoint: start, endPoint: end)
    }
}

// AuraFrameView.swift — gradient glow drawn per screen edge, driven by a shared AuraModel (canon §3).

import SwiftUI

enum AuraEdge { case top, bottom, left, right }

/// Shared observable driving all four edge windows so they animate in lockstep.
final class AuraModel: ObservableObject {
    @Published var color: Color = Palette.green
    @Published var visible = false
    @Published var edgeOpacity: Double = 0.55
}

struct AuraFrameView: View {
    @ObservedObject var model: AuraModel
    let edge: AuraEdge

    var body: some View {
        gradient
            .opacity(model.visible ? 1 : 0)
            .animation(.easeInOut(duration: 0.45), value: model.visible)
            .animation(.easeInOut(duration: 0.45), value: model.color)
            .animation(.easeInOut(duration: 0.45), value: model.edgeOpacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    private var gradient: LinearGradient {
        let lit = model.color.opacity(model.edgeOpacity)
        let start: UnitPoint
        let end: UnitPoint
        switch edge {
        case .top:    start = .top;      end = .bottom
        case .bottom: start = .bottom;   end = .top
        case .left:   start = .leading;  end = .trailing
        case .right:  start = .trailing; end = .leading
        }
        return LinearGradient(colors: [lit, .clear], startPoint: start, endPoint: end)
    }
}

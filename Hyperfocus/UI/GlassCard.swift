// GlassCard.swift — shared glass-card container style used by all card UIs (canon §2).

import SwiftUI

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 3
        content
    }
}

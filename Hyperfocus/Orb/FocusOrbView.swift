// FocusOrbView.swift — ring orb (canon §13 #25 v3): a glowing colored ring with a hollow white core.
// Idle = deep-red sleeping ring; engaged = morphs green (animated color crossfade). Hover partially
// fills the hollow center and brightens the glow. No particles.

import SwiftUI

/// Window footprint for the orb: sized so glow × hover × breathe never clips at the edges.
let orbWindowSize: CGFloat = 76

struct FocusOrbView: View {
    @EnvironmentObject var app: AppState
    @State private var breathe = false

    var body: some View {
        let visual = OrbVisual(state: app.context.state)
        let color = Color(red: visual.rgb.x, green: visual.rgb.y, blue: visual.rgb.z)
        let reduce = app.settings.reduceMotion
        let hovered = app.orbHovered
        let ringD = min(app.settings.orbSize * 1.3, 30)   // ring outer diameter
        let ringW = ringD * 0.16                          // ring thickness

        ZStack {
            // Clickability lives on the AppKit container's circular layer backing (see
            // FocusOrbWindowController.build) — no hit pixels needed in the SwiftUI tree.

            // Outer glow — blurred ring, comfortably inside the window so it is never clipped.
            Circle()
                .stroke(color, lineWidth: ringW * 2.2)
                .frame(width: ringD, height: ringD)
                .blur(radius: 8)
                .opacity(visual.glow * (hovered ? 0.95 : 0.6))

            // The ring itself.
            Circle()
                .stroke(color, lineWidth: ringW)
                .frame(width: ringD, height: ringD)
                .shadow(color: color.opacity(0.8), radius: 3)

            // Hollow white core — barely-there at rest, fills in on hover.
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.9), .white.opacity(0.25), .clear],
                                     center: .center,
                                     startRadius: 0, endRadius: (ringD - ringW) / 2))
                .frame(width: ringD - ringW * 2, height: ringD - ringW * 2)
                .opacity(hovered ? 0.55 : 0.10)
                .scaleEffect(hovered ? 1.0 : 0.72)
        }
        .scaleEffect((hovered ? 1.08 : 1.0) * (breathe && !reduce ? 1.045 : 1.0))
        .frame(width: orbWindowSize, height: orbWindowSize)
        .opacity(app.settings.orbOpacity)
        .animation(.easeInOut(duration: 0.6), value: app.context.state)   // the click morph red↔green
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
        .onAppear {
            guard !reduce else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { breathe = true }
        }
        .allowsHitTesting(false)   // the AppKit container owns all mouse handling
    }
}

/// Maps a session state to the ring's color and glow. Idle is a calm deep-red "sleep"; away is a
/// brighter red with a stronger glow so the two never read the same.
struct OrbVisual {
    let rgb: SIMD3<Double>
    let glow: Double

    init(state: SessionState) {
        switch state {
        case .idle, .exited:          rgb = SIMD3(0.92, 0.22, 0.26); glow = 0.45
        case .preparing, .countdown:  rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.90
        case .active:                 rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.75
        case .warning:                rgb = SIMD3(1.00, 0.72, 0.23); glow = 0.90
        case .away, .recovering:      rgb = SIMD3(1.00, 0.30, 0.30); glow = 1.00
        case .manualPaused:           rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.30
        case .completed:              rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.95
        }
    }
}

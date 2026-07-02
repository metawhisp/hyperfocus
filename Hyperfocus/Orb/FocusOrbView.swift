// FocusOrbView.swift — SwiftUI orb visuals per session state (canon §2, BRIEF Focus Orb states).

import SwiftUI

/// Fixed window footprint for the orb; the coloured core is `settings.orbSize`, centred, leaving
/// room for the glow so it is never clipped by the window bounds.
let orbWindowSize: CGFloat = 60

struct FocusOrbView: View {
    @EnvironmentObject var app: AppState
    @State private var pulse = false

    private var visual: OrbVisual { OrbVisual(state: app.context.state) }

    var body: some View {
        let core = max(18, app.settings.orbSize)
        let animate = visual.pulses && !app.settings.reduceMotion
        ZStack {
            // Peripheral glow — always faintly present so the idle orb is findable, brighter in
            // ready/active/warning/away, pulsing where the state calls for it.
            Circle()
                .fill(visual.glowColor)
                .frame(width: core, height: core)
                .blur(radius: 11)
                .opacity(visual.glowOpacity * (animate && pulse ? 1.0 : 0.65))
                .scaleEffect(animate && pulse ? 1.8 : 1.35)

            // Glass core with a coloured inner fill and a crisp rim so it reads as a deliberate control.
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(visual.coreColor.opacity(visual.coreOpacity)))
                .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1))
                .frame(width: core, height: core)
                .shadow(color: .black.opacity(0.5), radius: 5, y: 1)
        }
        .frame(width: orbWindowSize, height: orbWindowSize)
        .opacity(app.settings.orbOpacity)
        .onAppear {
            guard !app.settings.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

/// Maps a session state to the orb's look (BRIEF: idle glass, ready pulse, active core, warning,
/// away red, completed flash).
private struct OrbVisual {
    let coreColor: Color
    let glowColor: Color
    let coreOpacity: Double
    let glowOpacity: Double
    let pulses: Bool

    init(state: SessionState) {
        switch state {
        case .idle, .exited:
            coreColor = .white;        glowColor = .white;        coreOpacity = 0.18; glowOpacity = 0.30; pulses = false
        case .preparing, .countdown:
            coreColor = Palette.green; glowColor = Palette.green;  coreOpacity = 0.45; glowOpacity = 0.75; pulses = true
        case .active:
            coreColor = Palette.green; glowColor = Palette.green;  coreOpacity = 0.95; glowOpacity = 0.80; pulses = false
        case .warning:
            coreColor = Palette.amber; glowColor = Palette.amber;  coreOpacity = 0.90; glowOpacity = 0.85; pulses = true
        case .away, .recovering:
            coreColor = Palette.red;   glowColor = Palette.red;    coreOpacity = 0.95; glowOpacity = 0.90; pulses = true
        case .manualPaused:
            coreColor = Palette.green; glowColor = Palette.green;  coreOpacity = 0.35; glowOpacity = 0.30; pulses = false
        case .completed:
            coreColor = Palette.green; glowColor = Palette.green;  coreOpacity = 0.70; glowOpacity = 0.85; pulses = false
        }
    }
}

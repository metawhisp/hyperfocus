// FocusOrbView.swift — SwiftUI orb visuals per session state (canon §2, BRIEF Focus Orb states).

import SwiftUI

struct FocusOrbView: View {
    @EnvironmentObject var app: AppState
    @State private var pulse = false

    private var visual: OrbVisual { OrbVisual(state: app.context.state) }

    var body: some View {
        let size = app.settings.orbSize
        let animate = visual.pulses && !app.settings.reduceMotion
        ZStack {
            // Peripheral glow — pulses in ready/active/warning/away.
            Circle()
                .fill(visual.color)
                .frame(width: size, height: size)
                .blur(radius: 9)
                .opacity(visual.glows ? (animate && pulse ? 0.85 : 0.4) : 0.0)
                .scaleEffect(animate && pulse ? 1.7 : 1.25)

            // Glass core with a coloured inner fill.
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(visual.color.opacity(visual.coreOpacity)))
                .overlay(Circle().strokeBorder(.white.opacity(0.45), lineWidth: 0.5))
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
        }
        .frame(width: 56, height: 56)
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
    let color: Color
    let coreOpacity: Double
    let glows: Bool
    let pulses: Bool

    init(state: SessionState) {
        switch state {
        case .idle, .exited:
            color = .white;        coreOpacity = 0.06; glows = false; pulses = false
        case .preparing, .countdown:
            color = Palette.green; coreOpacity = 0.25; glows = true;  pulses = true
        case .active:
            color = Palette.green; coreOpacity = 0.95; glows = true;  pulses = false
        case .warning:
            color = Palette.amber; coreOpacity = 0.85; glows = true;  pulses = true
        case .away, .recovering:
            color = Palette.red;   coreOpacity = 0.95; glows = true;  pulses = true
        case .manualPaused:
            color = Palette.green; coreOpacity = 0.30; glows = false; pulses = false
        case .completed:
            color = Palette.green; coreOpacity = 0.70; glows = true;  pulses = false
        }
    }
}

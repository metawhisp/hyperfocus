// FocusOrbView.swift — living particle-sphere orb (canon §13 #25): deep-red calm sleep when idle,
// morphs green when engaged. A dense Fibonacci lattice of fine particles over a soft gradient core
// (SwiftUI Canvas + TimelineView) — reads as a glowing dotted sphere, not scattered spikes.

import SwiftUI

/// Window footprint for the orb: sized so the glow and the hover scale NEVER clip at the edges.
let orbWindowSize: CGFloat = 76

struct FocusOrbView: View {
    @EnvironmentObject var app: AppState
    @State private var transition = ColorTransition()

    var body: some View {
        let visual = OrbVisual(state: app.context.state)
        let reduce = app.settings.reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduce)) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, date: timeline.date, visual: visual, reduce: reduce)
            }
        }
        .frame(width: orbWindowSize, height: orbWindowSize)
        .scaleEffect(app.orbHovered ? 1.08 : 1.0)                        // hover: "I'm alive"
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: app.orbHovered)
        .opacity(app.settings.orbOpacity)
        .onChange(of: app.context.state) { oldState, _ in
            // Morph from the color currently ON SCREEN (not the old state's canonical color), so a
            // rapid re-click mid-morph reverses smoothly instead of popping to full green first.
            let displayed = transition.current(toward: OrbVisual(state: oldState).rgb, at: Date())
            transition.begin(from: displayed)
        }
        .allowsHitTesting(false)   // the AppKit container owns all mouse handling
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize, date: Date,
                      visual: OrbVisual, reduce: Bool) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let t = reduce ? 0 : date.timeIntervalSinceReferenceDate
        let speed = visual.speed * (app.orbHovered ? 1.7 : 1.0)
        let rotY = t * speed
        let rotX = t * speed * 0.31
        let pulse = (visual.pulses && !reduce) ? 1.0 + 0.04 * sin(t * visual.pulseRate) : 1.0
        // Reduce-motion pauses the timeline, so an animated morph would freeze mid-transition and
        // show a stale color — jump straight to the target instead.
        let rgb = reduce ? visual.rgb : transition.current(toward: visual.rgb, at: date)
        let color = Color(red: rgb.x, green: rgb.y, blue: rgb.z)
        // Radius budget: glow (×1.9) times hover scale (×1.08) must stay inside the window.
        let radius = min(app.settings.orbSize * 0.75, orbWindowSize / 2 / (1.9 * 1.08) - 0.5) * pulse

        // 1. Soft outer glow — fits fully inside the window, never clipped.
        let glowR = radius * 1.9
        ctx.fill(
            Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR,
                                   width: glowR * 2, height: glowR * 2)),
            with: .radialGradient(
                Gradient(colors: [color.opacity(visual.glow * (app.orbHovered ? 0.5 : 0.38)), .clear]),
                center: center, startRadius: radius * 0.55, endRadius: glowR)
        )

        // 2. Gradient core — gives the sphere a solid luminous body under the particles.
        ctx.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                   width: radius * 2, height: radius * 2)),
            with: .radialGradient(
                Gradient(colors: [color.opacity(0.34), color.opacity(0.10), color.opacity(0.02)]),
                center: CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.25),
                startRadius: 0, endRadius: radius * 1.15)
        )

        // 3. Dense fine particles: rotate around Y then X; depth drives size, brightness, whitening.
        let cy = cos(rotY), sy = sin(rotY), cx = cos(rotX), sx = sin(rotX)
        for p in Self.spherePoints {
            let x1 = p.x * cy + p.z * sy
            let z1 = -p.x * sy + p.z * cy
            let y1 = p.y * cx - z1 * sx
            let z2 = p.y * sx + z1 * cx
            let depth = (z2 + 1) / 2                       // 0 = back … 1 = front
            let px = center.x + x1 * radius
            let py = center.y + y1 * radius
            let dotR = (0.30 + 0.50 * depth) * radius / 17
            let dotColor = Color(red: rgb.x + (1 - rgb.x) * depth * 0.45,
                                 green: rgb.y + (1 - rgb.y) * depth * 0.45,
                                 blue: rgb.z + (1 - rgb.z) * depth * 0.45)
            ctx.fill(Path(ellipseIn: CGRect(x: px - dotR, y: py - dotR,
                                            width: dotR * 2, height: dotR * 2)),
                     with: .color(dotColor.opacity(0.16 + 0.74 * depth)))
        }
    }

    /// Densely, evenly distributed points on a unit sphere (Fibonacci lattice).
    private static let spherePoints: [SIMD3<Double>] = {
        let n = 420
        let golden = Double.pi * (3 - sqrt(5))
        return (0..<n).map { i in
            let y = 1 - (Double(i) / Double(n - 1)) * 2
            let r = (1 - y * y).squareRoot()
            let a = golden * Double(i)
            return SIMD3(cos(a) * r, y, sin(a) * r)
        }
    }()
}

/// Eased color interpolation between orb states (the click "morph").
private struct ColorTransition {
    private var from: SIMD3<Double>?
    private var start: Date?
    private let duration: TimeInterval = 0.7

    mutating func begin(from rgb: SIMD3<Double>) {
        from = rgb
        start = Date()
    }

    func current(toward target: SIMD3<Double>, at date: Date) -> SIMD3<Double> {
        guard let from, let start else { return target }
        let t = min(1, max(0, date.timeIntervalSince(start) / duration))
        let eased = t * t * (3 - 2 * t)
        return from + (target - from) * eased
    }
}

/// Maps a session state to the orb's look. Idle is a calm deep-red "sleep"; away is a brighter,
/// faster red so the two never read the same.
struct OrbVisual {
    let rgb: SIMD3<Double>
    let glow: Double
    let speed: Double
    let pulses: Bool
    let pulseRate: Double

    init(state: SessionState) {
        switch state {
        case .idle, .exited:
            rgb = SIMD3(0.92, 0.22, 0.26); glow = 0.45; speed = 0.22; pulses = true;  pulseRate = 0.9
        case .preparing, .countdown:
            rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.85; speed = 0.85; pulses = true;  pulseRate = 2.0
        case .active:
            rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.75; speed = 0.45; pulses = false; pulseRate = 0
        case .warning:
            rgb = SIMD3(1.00, 0.72, 0.23); glow = 0.90; speed = 0.95; pulses = true;  pulseRate = 3.0
        case .away, .recovering:
            rgb = SIMD3(1.00, 0.30, 0.30); glow = 1.00; speed = 1.30; pulses = true;  pulseRate = 3.6
        case .manualPaused:
            rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.30; speed = 0.12; pulses = false; pulseRate = 0
        case .completed:
            rgb = SIMD3(0.16, 0.92, 0.55); glow = 0.95; speed = 0.60; pulses = true;  pulseRate = 1.4
        }
    }
}

// FocusOrbView.swift — production orb v4 "ring ⇄ particles" (canon §13 #25, user-approved design).
// Off/idle = calm red ring. Powering on = the ring dissolves into a BRIGHT rotating green particle
// sphere — same dots, two forms. The light radiates from the sphere itself (inner bloom + halo):
// an ADHD-grade beacon, not a whisper. Warning/away recolor the lit sphere amber/red.

import SwiftUI

/// Window footprint for the orb: sized so halo × hover scale never clips at the edges.
let orbWindowSize: CGFloat = 76

// MARK: Renderer — one entity, two forms (also drives the DEBUG live previews)

struct RingToParticlesOrb: View {
    let t: Double          // drives sphere rotation
    let progress: Double   // 0 = ring (off) … 1 = rotating particle sphere (on)
    var diameter: CGFloat = 46
    var brightness: Double = 2.2
    /// When set, overrides the built-in off→on color mix (production drives color by session state).
    var rgbOverride: SIMD3<Double>? = nil

    private static let count = 240
    // Sorted by screen angle so ring dot i flies to a sphere point at a similar angle — the ring
    // "inflates" into the sphere instead of scrambling through the middle.
    private static let points: [SIMD3<Double>] = {
        let golden = Double.pi * (3 - sqrt(5))
        let lattice = (0..<count).map { i -> SIMD3<Double> in
            let y = 1 - (Double(i) / Double(count - 1)) * 2
            let r = (1 - y * y).squareRoot()
            let a = golden * Double(i)
            return SIMD3(cos(a) * r, y, sin(a) * r)
        }
        return lattice.sorted { atan2($0.y, $0.x) < atan2($1.y, $1.x) }
    }()

    static let offRGB = SIMD3(0.85, 0.20, 0.22)
    static let onRGB = SIMD3(0.16, 0.92, 0.55)

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let p = progress * progress * (3 - 2 * progress)          // eased
            let R = Double(diameter) / 2 * 0.62
            let rgb = rgbOverride ?? (Self.offRGB + (Self.onRGB - Self.offRGB) * p)
            let color = Color(red: rgb.x, green: rgb.y, blue: rgb.z)

            // Outer halo — visible ember when off, BLAZING when on (scales with brightness).
            // Multi-stop tail so the glow fades smoothly to 0% — a 2-stop linear ramp reads as a
            // hard-edged disc on light backgrounds.
            let glowR = R * 2.3
            let haloAlpha = min(1.0, (0.10 + 0.38 * p) * brightness)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - glowR, y: c.y - glowR,
                                            width: glowR * 2, height: glowR * 2)),
                     with: .radialGradient(
                        Gradient(stops: [
                            .init(color: color.opacity(haloAlpha), location: 0.00),
                            .init(color: color.opacity(haloAlpha * 0.45), location: 0.40),
                            .init(color: color.opacity(haloAlpha * 0.18), location: 0.65),
                            .init(color: color.opacity(haloAlpha * 0.05), location: 0.85),
                            .init(color: .clear, location: 1.00),
                        ]),
                        center: c, startRadius: R * 0.35, endRadius: glowR))
            // Inner bloom — the sphere itself radiates once powered on.
            if p > 0.01 {
                let bloomR = R * 1.25
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - bloomR, y: c.y - bloomR,
                                                width: bloomR * 2, height: bloomR * 2)),
                         with: .radialGradient(
                            Gradient(colors: [color.opacity(min(1.0, 0.55 * p * brightness)),
                                              color.opacity(min(1.0, 0.18 * p * brightness)),
                                              .clear]),
                            center: c, startRadius: 0, endRadius: bloomR))
            }

            let rotY = t * 0.55, rotX = t * 0.21
            let cy = cos(rotY), sy = sin(rotY), cx = cos(rotX), sx = sin(rotX)
            for (i, pt) in Self.points.enumerated() {
                // Form A: a point on the flat ring (dots overlap into a solid circle line).
                let a = 2 * Double.pi * Double(i) / Double(Self.count)
                let ringX = cos(a) * R, ringY = sin(a) * R

                // Form B: the same point on the rotating sphere.
                let x1 = pt.x * cy + pt.z * sy
                let z1 = -pt.x * sy + pt.z * cy
                let y1 = pt.y * cx - z1 * sx
                let z2 = pt.y * sx + z1 * cx
                let depth = (z2 + 1) / 2
                let sphX = x1 * R * 1.05, sphY = y1 * R * 1.05

                let x = ringX + (sphX - ringX) * p
                let y = ringY + (sphY - ringY) * p
                let d = 0.55 + (depth - 0.55) * p
                let sizeBoost = 1 + 0.15 * (brightness - 1) * p
                let sphereDotR = (0.30 + 0.50 * depth) * R / 14
                let dotR = (1.15 + (sphereDotR - 1.15) * p) * sizeBoost
                let sphereAlpha = 0.35 + 0.75 * depth
                let alphaBoost = 1 + 0.25 * (brightness - 1) * p
                let bright = min(1.0, (0.95 + (sphereAlpha - 0.95) * p) * alphaBoost)
                let whiten = d * 0.60 * p
                let dotColor = Color(red: rgb.x + (1 - rgb.x) * whiten,
                                     green: rgb.y + (1 - rgb.y) * whiten,
                                     blue: rgb.z + (1 - rgb.z) * whiten)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x + x - dotR, y: c.y + y - dotR,
                                                width: dotR * 2, height: dotR * 2)),
                         with: .color(dotColor.opacity(bright)))
            }
        }
    }
}

// MARK: Session state → orb style

struct OrbMorphStyle {
    let progress: Double        // 0 ring … 1 sphere
    let rgb: SIMD3<Double>
    let brightness: Double
    let pulseRate: Double       // 0 = steady

    /// Angry-orb body language (canon #40): warning grows a little and jitters; away grows
    /// on toward ×2 (ramped over 7 s in the view) and shakes hard with angry eyes.
    var baseScale: Double {
        switch angerStage { case 2: return 1.35; case 1: return 1.15; default: return 1 }
    }
    var jitterAmp: Double {
        switch angerStage { case 2: return 3.6; case 1: return 1.6; default: return 0 }
    }
    let angerStage: Int         // 0 calm · 1 warning · 2 away/recovering

    init(state: SessionState) {
        let green = RingToParticlesOrb.onRGB
        let red = RingToParticlesOrb.offRGB
        let amber = SIMD3(1.00, 0.72, 0.23)
        let alarmRed = SIMD3(1.00, 0.30, 0.30)
        switch state {
        case .idle, .exited:
            progress = 0; rgb = red;      brightness = 3.0; pulseRate = 0; angerStage = 0
        case .preparing, .countdown:
            progress = 1; rgb = green;    brightness = 2.7; pulseRate = 1.6; angerStage = 0
        case .active:
            progress = 1; rgb = green;    brightness = 2.7; pulseRate = 0; angerStage = 0
        case .warning:
            progress = 1; rgb = amber;    brightness = 2.4; pulseRate = 3.0; angerStage = 1
        case .away, .recovering:
            progress = 1; rgb = alarmRed; brightness = 2.6; pulseRate = 3.6; angerStage = 2
        case .manualPaused:
            progress = 1; rgb = green;    brightness = 1.1; pulseRate = 0; angerStage = 0
        case .completed:
            progress = 1; rgb = green;    brightness = 2.6; pulseRate = 1.4; angerStage = 0
        }
    }
}

// MARK: Morph animator — eases progress and color toward the current state's targets

private struct MorphAnimator {
    private var fromP: Double?
    private var fromRGB: SIMD3<Double>?
    private var start: Date?
    private let duration: TimeInterval = 0.9

    private func eased(_ now: Date) -> Double {
        guard let start else { return 1 }
        let t = min(1, max(0, now.timeIntervalSince(start) / duration))
        return t * t * (3 - 2 * t)
    }

    func progress(toward target: Double, at now: Date) -> Double {
        guard let fromP else { return target }
        return fromP + (target - fromP) * eased(now)
    }

    func color(toward target: SIMD3<Double>, at now: Date) -> SIMD3<Double> {
        guard let fromRGB else { return target }
        return fromRGB + (target - fromRGB) * eased(now)
    }

    /// Start a new transition from whatever is currently displayed (smooth even mid-morph).
    mutating func retarget(fromOld old: OrbMorphStyle, at now: Date) {
        fromP = progress(toward: old.progress, at: now)
        fromRGB = color(toward: old.rgb, at: now)
        start = now
    }

    func isAnimating(at now: Date) -> Bool {
        guard let start else { return false }
        return now.timeIntervalSince(start) < duration
    }
}

// MARK: Production orb view

struct FocusOrbView: View {
    @EnvironmentObject var app: AppState
    @State private var morph = MorphAnimator()
    @State private var animEpoch = 0   // bumped after a morph ends so `paused` re-evaluates
    @State private var angerSince: Date?   // when the away (stage-2) rage started — drives the ×2 growth

    var body: some View {
        let _ = animEpoch
        let style = OrbMorphStyle(state: app.context.state)
        let reduce = app.settings.reduceMotion
        let life = app.orbLife.beat        // idle liveliness beat (canon #39), nil most of the time
        // Battery: the idle red ring is static — stop the render loop entirely once the morph is
        // done (measured 5-7% CPU when redrawing the static ring at 30 fps). A liveliness beat
        // un-pauses it for its ~2 s and it re-pauses after.
        let isStatic = style.progress == 0 && style.pulseRate == 0
        let paused = reduce || (isStatic && life == nil && !morph.isAnimating(at: Date()))
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: paused)) { tl in
            let now = tl.date
            let t = reduce ? 0 : now.timeIntervalSinceReferenceDate
            let p = reduce ? style.progress : morph.progress(toward: style.progress, at: now)
            let rgb = reduce ? style.rgb : morph.color(toward: style.rgb, at: now)
            let pulse = (style.pulseRate > 0 && !reduce) ? 1 + 0.10 * sin(t * style.pulseRate) : 1
            let hoverBoost = app.orbHovered ? 1.18 : 1.0

            // A liveliness beat only plays over the calm idle ring (not mid-morph, not reduce-motion).
            let f = (life != nil && !reduce && isStatic)
                ? OrbLifeFrame.compute(life!.variant, elapsed: now.timeIntervalSince(life!.start),
                                       dir: life!.dir)
                : OrbLifeFrame()

            // Angry body language (canon #40): warning grows to 1.15 and jitters; away keeps
            // growing toward ×2 over 7 s, shakes harder and wears angry eyes.
            let anger = style.angerStage
            let angerScale: Double = {
                guard anger > 0, !reduce else { return 1 }
                if anger == 1 { return style.baseScale }
                let elapsed = angerSince.map { now.timeIntervalSince($0) } ?? 0
                return style.baseScale + (2.0 - style.baseScale) * min(1, elapsed / 7.0)
            }()
            let jitter = reduce ? 0 : style.jitterAmp * (anger == 2 ? min(2.0, angerScale) / 1.6 : 1)
            let jx = anger > 0 ? (sin(t * 37) + sin(t * 51) * 0.6) * jitter : 0
            let jy = anger > 0 ? (cos(t * 43) + sin(t * 59) * 0.6) * jitter * 0.7 : 0

            ZStack {
                RingToParticlesOrb(t: t, progress: max(p, f.progress), diameter: 48,
                                   brightness: style.brightness * pulse * hoverBoost * f.brightnessMul,
                                   rgbOverride: rgb)
                if f.eyeFade > 0 {
                    OrbEyes(d: 48, leftOpen: f.leftOpen, rightOpen: f.rightOpen, gaze: f.gaze)
                        .opacity(f.eyeFade)
                }
                if anger > 0 && !reduce {
                    AngryFace(d: 48, rage: anger == 2 ? 1 : 0.4)
                }
            }
            .rotationEffect(.degrees(f.rotationDeg))
            .offset(x: f.slideNorm * 8 + jx, y: jy)
            .scaleEffect(f.scale * angerScale)
        }
        .frame(width: orbWindowSize, height: orbWindowSize)
        .scaleEffect(app.orbHovered ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: app.orbHovered)
        .opacity(app.settings.orbOpacity)
        .onChange(of: app.context.state) { oldState, newState in
            morph.retarget(fromOld: OrbMorphStyle(state: oldState), at: Date())
            // Rage clock: starts when entering away, keeps running through recovering.
            let stage = OrbMorphStyle(state: newState).angerStage
            if stage == 2 { if angerSince == nil { angerSince = Date() } } else { angerSince = nil }
            animEpoch += 1
            // Re-evaluate `paused` once the morph lands (nothing else re-renders the body then).
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { animEpoch += 1 }
        }
        .allowsHitTesting(false)   // the AppKit container owns all mouse handling
    }
}

/// Angry brows + eyes for the raging orb (canon #40, gallery style V2). `rage` 0…1 slants
/// the brows harder as the orb goes from warning to away.
struct AngryFace: View {
    let d: CGFloat
    let rage: Double

    var body: some View {
        let tilt = 8 + 20 * rage
        VStack(spacing: d * 0.06) {
            HStack(spacing: d * 0.14) {
                Capsule().fill(.white).frame(width: d * 0.16, height: d * 0.05)
                    .rotationEffect(.degrees(tilt))
                Capsule().fill(.white).frame(width: d * 0.16, height: d * 0.05)
                    .rotationEffect(.degrees(-tilt))
            }
            HStack(spacing: d * 0.16) {
                Capsule().fill(.white).frame(width: d * 0.10, height: d * 0.16)
                Capsule().fill(.white).frame(width: d * 0.10, height: d * 0.16)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 1)
    }
}

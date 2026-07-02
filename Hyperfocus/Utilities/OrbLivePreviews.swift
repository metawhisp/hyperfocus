// OrbLivePreviews.swift — DEBUG-only LIVE animated orb gallery (HF_ORB_PREVIEW_LIVE=1).
// Concept per product direction: red = switched OFF (dark, dead inside, thin dim rim);
// green = switched ON — the light and the animation happen INSIDE the sphere, not on the edges.

#if DEBUG
import SwiftUI
import AppKit

private let onGreen = Color(red: 0.16, green: 0.92, blue: 0.55)
private let offRed = Color(red: 0.85, green: 0.20, blue: 0.22)

/// Pure function of time — used live (TimelineView) and for verification stills.
struct InnerLitOrb: View {
    let variant: Int
    let on: Bool
    let t: Double

    var body: some View {
        let d: CGFloat = 46
        let color = on ? onGreen : offRed
        ZStack {
            // Faint ambient — barely-there, so the edges never dominate.
            Circle()
                .fill(RadialGradient(colors: [color.opacity(on ? 0.16 : 0.07), .clear],
                                     center: .center, startRadius: d * 0.35, endRadius: d))
                .frame(width: d * 2, height: d * 2)

            // Dark sphere body + inner light, clipped to the sphere.
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 0.13, green: 0.14, blue: 0.17),
                                                  Color.black.opacity(0.92)],
                                         center: UnitPoint(x: 0.40, y: 0.34),
                                         startRadius: 1, endRadius: d * 0.62))
                if on { innerLight(d: d) }
            }
            .frame(width: d, height: d)
            .clipShape(Circle())

            // Thin rim — dim when off, only slightly present when on (never the main light).
            Circle()
                .strokeBorder(color.opacity(on ? 0.50 : 0.20), lineWidth: 1.3)
                .frame(width: d, height: d)
                .blur(radius: 0.4)
        }
        .frame(width: 116, height: 112)
    }

    @ViewBuilder
    private func innerLight(d: CGFloat) -> some View {
        switch variant {
        case 1:   // V1 «Дыхание» — soft core glow breathing from inside
            let p = 0.5 + 0.5 * sin(t * 1.6)
            Circle()
                .fill(RadialGradient(colors: [onGreen.opacity(0.85), onGreen.opacity(0.22), .clear],
                                     center: .center, startRadius: 0, endRadius: d * 0.42))
                .scaleEffect(0.72 + 0.22 * p)
                .opacity(0.55 + 0.45 * p)
                .blur(radius: 3)

        case 2:   // V2 «Вихрь» — glowing blobs slowly swirling inside
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let w = 0.9 + Double(i) * 0.35
                    let ph = Double(i) * 2.1
                    Circle()
                        .fill(onGreen.opacity(0.42))
                        .frame(width: d * 0.52, height: d * 0.52)
                        .offset(x: cos(t * w + ph) * d * 0.18,
                                y: sin(t * w * 0.8 + ph) * d * 0.18)
                        .blur(radius: 7)
                }
                Circle()
                    .fill(RadialGradient(colors: [onGreen.opacity(0.30), .clear],
                                         center: .center, startRadius: 0, endRadius: d * 0.4))
            }

        case 3:   // V3 «Частицы» — the rotating particle sphere lives INSIDE as the light source
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [onGreen.opacity(0.28), .clear],
                                         center: .center, startRadius: 0, endRadius: d * 0.42))
                InnerParticles(t: t, diameter: d * 0.86)
            }

        default:  // V4 «Пульс-дрейф» — a hotspot drifting and flickering like contained energy
            let fx = sin(t * 0.7) * d * 0.14
            let fy = cos(t * 1.13) * d * 0.11
            let flicker = 0.55 + 0.25 * sin(t * 5.3) + 0.20 * sin(t * 2.2)
            Circle()
                .fill(RadialGradient(colors: [onGreen.opacity(0.9), onGreen.opacity(0.25), .clear],
                                     center: .center, startRadius: 0, endRadius: d * 0.34))
                .offset(x: fx, y: fy)
                .opacity(max(0.25, flicker))
                .blur(radius: 4)
        }
    }
}

/// Rotating Fibonacci particle lattice, glowing, for variant 3.
private struct InnerParticles: View {
    let t: Double
    let diameter: CGFloat

    private static let points: [SIMD3<Double>] = {
        let n = 240
        let golden = Double.pi * (3 - sqrt(5))
        return (0..<n).map { i in
            let y = 1 - (Double(i) / Double(n - 1)) * 2
            let r = (1 - y * y).squareRoot()
            let a = golden * Double(i)
            return SIMD3(cos(a) * r, y, sin(a) * r)
        }
    }()

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2 * 0.82
            let rotY = t * 0.5, rotX = t * 0.19
            let cy = cos(rotY), sy = sin(rotY), cx = cos(rotX), sx = sin(rotX)
            for p in Self.points {
                let x1 = p.x * cy + p.z * sy
                let z1 = -p.x * sy + p.z * cy
                let y1 = p.y * cx - z1 * sx
                let z2 = p.y * sx + z1 * cx
                let depth = (z2 + 1) / 2
                let dotR = (0.28 + 0.45 * depth) * radius / 16
                ctx.fill(Path(ellipseIn: CGRect(x: c.x + x1 * radius - dotR,
                                                y: c.y + y1 * radius - dotR,
                                                width: dotR * 2, height: dotR * 2)),
                         with: .color(Color(red: 0.16 + 0.5 * depth, green: 0.92, blue: 0.55)
                            .opacity(0.10 + 0.65 * depth)))
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: V5 — the red ring ITSELF morphs into rotating particles (one entity, two forms)

struct RingToParticlesOrb: View {
    let t: Double          // drives sphere rotation
    let progress: Double   // 0 = red ring (off) … 1 = green rotating particle sphere (on)
    var diameter: CGFloat = 46
    var brightness: Double = 2.0   // ADHD product: ON must BLAZE green, not whisper

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

    private static let offRGB = SIMD3(0.85, 0.20, 0.22)
    private static let onRGB = SIMD3(0.16, 0.92, 0.55)

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let p = progress * progress * (3 - 2 * progress)          // eased
            let R = Double(diameter) / 2 * 0.62
            let rgb = Self.offRGB + (Self.onRGB - Self.offRGB) * p
            let color = Color(red: rgb.x, green: rgb.y, blue: rgb.z)

            // Outer halo — visible ember when off, BLAZING when on (scales with brightness).
            let glowR = R * 2.3
            let haloAlpha = min(1.0, (0.10 + 0.38 * p) * brightness)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - glowR, y: c.y - glowR,
                                            width: glowR * 2, height: glowR * 2)),
                     with: .radialGradient(Gradient(colors: [color.opacity(haloAlpha), .clear]),
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

/// Auto-cycling live demo: off ring → powers on into the rotating sphere → powers off.
private struct RingMorphDemoCell: View {
    var brightness: Double = 2.0
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            RingToParticlesOrb(t: t, progress: Self.progress(at: t), diameter: 64,
                               brightness: brightness)
                .frame(width: 170, height: 150)
        }
    }

    /// 6 s cycle: hold off 1.2 s → power on 0.9 s → hold on 2.7 s → power off 0.9 s → hold off.
    private static func progress(at t: Double) -> Double {
        let phase = t.truncatingRemainder(dividingBy: 6.0)
        switch phase {
        case ..<1.2: return 0
        case ..<2.1: return (phase - 1.2) / 0.9
        case ..<4.8: return 1
        case ..<5.7: return 1 - (phase - 4.8) / 0.9
        default:     return 0
        }
    }
}

private struct LiveOrbCell: View {
    let variant: Int
    let on: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            InnerLitOrb(variant: variant, on: on, t: tl.date.timeIntervalSinceReferenceDate)
        }
    }
}

struct OrbLiveGalleryView: View {
    private let names = ["V1 · Дыхание", "V2 · Вихрь", "V3 · Частицы", "V4 · Пульс-дрейф"]

    var body: some View {
        VStack(spacing: 14) {
            Text("Кольцо ⇄ Частицы: три уровня яркости (автоцикл выкл → ВКЛ → выкл)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 6) {
                    RingMorphDemoCell(brightness: 1.5)
                    Text("Я1 · Ярко").font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                VStack(spacing: 6) {
                    RingMorphDemoCell(brightness: 2.2)
                    Text("Я2 · Очень ярко").font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                VStack(spacing: 6) {
                    RingMorphDemoCell(brightness: 3.0)
                    Text("Я3 · Неон").font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(26)
        .background(Color(red: 0.055, green: 0.065, blue: 0.09))
    }
}

@MainActor
enum OrbLivePreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 700, height: 380),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Orb Live Preview"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: OrbLiveGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

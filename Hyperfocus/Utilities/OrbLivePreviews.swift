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
            Text("Вкл (зелёный, свет внутри) · Выкл (красный, погасший)")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
            HStack(alignment: .top, spacing: 22) {
                ForEach(0..<4, id: \.self) { i in
                    VStack(spacing: 8) {
                        LiveOrbCell(variant: i + 1, on: true)
                        LiveOrbCell(variant: i + 1, on: false)
                        Text(names[i])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
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

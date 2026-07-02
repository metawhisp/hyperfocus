// OrbPreviews.swift — DEBUG-only orb design gallery (HF_ORB_PREVIEW=1): renders candidate orb looks
// side by side WITHOUT touching the production FocusOrbView. The user picks; only then we ship.

#if DEBUG
import SwiftUI
import AppKit

// MARK: Variant A — Glass dot (v1, commit c187ca0)

private struct GlassOrbPreview: View {
    let color: Color
    var body: some View {
        ZStack {
            Circle().fill(color).frame(width: 26, height: 26)
                .blur(radius: 10).opacity(0.55).scaleEffect(1.5)
            Circle().fill(Color.white.opacity(0.14))
                .overlay(Circle().fill(color.opacity(0.85)))
                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 0.6))
                .frame(width: 26, height: 26)
        }
    }
}

// MARK: Variant B — Particle sphere (v2, commit history)

private struct ParticleOrbPreview: View {
    let color: Color
    private static let points: [SIMD3<Double>] = {
        let n = 420
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
            let radius: CGFloat = 17
            let rc = NSColor(self.color).usingColorSpace(.sRGB)!
            let rgb = SIMD3(Double(rc.redComponent), Double(rc.greenComponent), Double(rc.blueComponent))
            let glowR = radius * 1.9
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - glowR, y: c.y - glowR, width: glowR * 2, height: glowR * 2)),
                     with: .radialGradient(Gradient(colors: [color.opacity(0.35), .clear]),
                                           center: c, startRadius: radius * 0.5, endRadius: glowR))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)),
                     with: .radialGradient(Gradient(colors: [color.opacity(0.34), color.opacity(0.06)]),
                                           center: CGPoint(x: c.x - 4, y: c.y - 4), startRadius: 0, endRadius: radius * 1.15))
            let rotY = 1.7, rotX = 0.55
            let cy = cos(rotY), sy = sin(rotY), cx = cos(rotX), sx = sin(rotX)
            for p in Self.points {
                let x1 = p.x * cy + p.z * sy
                let z1 = -p.x * sy + p.z * cy
                let y1 = p.y * cx - z1 * sx
                let z2 = p.y * sx + z1 * cx
                let depth = (z2 + 1) / 2
                let dotR = (0.30 + 0.50 * depth) * radius / 17
                let col = Color(red: rgb.x + (1 - rgb.x) * depth * 0.45,
                                green: rgb.y + (1 - rgb.y) * depth * 0.45,
                                blue: rgb.z + (1 - rgb.z) * depth * 0.45)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x + x1 * radius - dotR, y: c.y + y1 * radius - dotR,
                                                width: dotR * 2, height: dotR * 2)),
                         with: .color(col.opacity(0.16 + 0.74 * depth)))
            }
        }
    }
}

// MARK: Variant C — Ring with hollow core (v3, current prod)

private struct RingOrbPreview: View {
    let color: Color
    var body: some View {
        let ringD: CGFloat = 29, ringW: CGFloat = 4.6
        ZStack {
            Circle().stroke(color, lineWidth: ringW * 2.2).frame(width: ringD, height: ringD)
                .blur(radius: 8).opacity(0.6)
            Circle().stroke(color, lineWidth: ringW).frame(width: ringD, height: ringD)
                .shadow(color: color.opacity(0.8), radius: 3)
            Circle().fill(RadialGradient(colors: [.white.opacity(0.9), .white.opacity(0.25), .clear],
                                         center: .center, startRadius: 0, endRadius: (ringD - ringW) / 2))
                .frame(width: ringD - ringW * 2, height: ringD - ringW * 2)
                .opacity(0.10).scaleEffect(0.72)
        }
    }
}

// MARK: Variant D — Plasma (reference-style: dark core, flowing uneven luminous rim)

private struct PlasmaOrbPreview: View {
    let color: Color
    let seed: Double   // shifts the hot arcs so red/green don't look identical

    private func arc(_ from: Double, _ to: Double, width: CGFloat, blur: CGFloat,
                     _ col: Color, d: CGFloat) -> some View {
        Circle().trim(from: from, to: to)
            .stroke(col, style: StrokeStyle(lineWidth: width, lineCap: .round))
            .frame(width: d, height: d)
            .rotationEffect(.degrees(seed * 360 - 90))
            .blur(radius: blur)
    }

    var body: some View {
        let d: CGFloat = 42
        ZStack {
            // bloom halo
            Circle().fill(RadialGradient(colors: [color.opacity(0.45), .clear],
                                         center: .center, startRadius: d * 0.30, endRadius: d * 0.95))
                .frame(width: d * 1.9, height: d * 1.9)
            // dark sphere body with faint top-left tint
            Circle().fill(RadialGradient(colors: [color.opacity(0.28), Color.black.opacity(0.78)],
                                         center: UnitPoint(x: 0.36, y: 0.32),
                                         startRadius: 1, endRadius: d * 0.62))
                .frame(width: d, height: d)
            // base rim — thin, slightly blurred
            Circle().stroke(color.opacity(0.85), lineWidth: 1.6)
                .frame(width: d, height: d).blur(radius: 0.6)
            // uneven angular brightness (liquid rim)
            Circle().stroke(
                AngularGradient(stops: [
                    .init(color: color.opacity(0.05), location: 0.00),
                    .init(color: color.opacity(0.85), location: 0.10),
                    .init(color: .white.opacity(0.95), location: 0.16),
                    .init(color: color.opacity(0.35), location: 0.28),
                    .init(color: color.opacity(0.90), location: 0.45),
                    .init(color: .white.opacity(0.80), location: 0.52),
                    .init(color: color.opacity(0.20), location: 0.66),
                    .init(color: color.opacity(0.75), location: 0.82),
                    .init(color: .white.opacity(0.65), location: 0.90),
                    .init(color: color.opacity(0.05), location: 1.00),
                ], center: .center, angle: .degrees(seed * 360)),
                lineWidth: 3.2)
                .frame(width: d, height: d).blur(radius: 1.4)
            // hot liquid highlights
            arc(0.03 + seed * 0.05, 0.15 + seed * 0.05, width: 2.6, blur: 1.1, .white.opacity(0.95), d: d)
            arc(0.44, 0.53, width: 2.2, blur: 1.3, .white.opacity(0.8), d: d)
            arc(0.72, 0.84, width: 2.8, blur: 1.6, color.opacity(0.95), d: d)
        }
    }
}

// MARK: Variant E — Nebula (plasma + inner wisps)

private struct NebulaOrbPreview: View {
    let color: Color
    var body: some View {
        ZStack {
            PlasmaOrbPreview(color: color, seed: 0.62)
            // interior wisps
            Ellipse().fill(color.opacity(0.30)).frame(width: 20, height: 9)
                .rotationEffect(.degrees(-24)).offset(x: -4, y: 5).blur(radius: 4)
            Ellipse().fill(Color.white.opacity(0.16)).frame(width: 13, height: 6)
                .rotationEffect(.degrees(18)).offset(x: 6, y: -5).blur(radius: 3)
        }
    }
}

// MARK: Gallery

struct OrbGalleryView: View {
    private let green = Color(red: 0.16, green: 0.92, blue: 0.55)
    private let red = Color(red: 0.92, green: 0.22, blue: 0.26)

    var body: some View {
        let cells: [(String, AnyView, AnyView)] = [
            ("A · Glass (v1)", AnyView(GlassOrbPreview(color: green)), AnyView(GlassOrbPreview(color: red))),
            ("B · Particles (v2)", AnyView(ParticleOrbPreview(color: green)), AnyView(ParticleOrbPreview(color: red))),
            ("C · Ring (сейчас)", AnyView(RingOrbPreview(color: green)), AnyView(RingOrbPreview(color: red))),
            ("D · Plasma", AnyView(PlasmaOrbPreview(color: green, seed: 0.18)), AnyView(PlasmaOrbPreview(color: red, seed: 0.18))),
            ("E · Nebula", AnyView(NebulaOrbPreview(color: green)), AnyView(NebulaOrbPreview(color: red))),
        ]
        HStack(alignment: .top, spacing: 18) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                VStack(spacing: 6) {
                    cell.1.frame(width: 108, height: 100)
                    cell.2.frame(width: 108, height: 100)
                    Text(cell.0)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(24)
        .background(Color(red: 0.055, green: 0.065, blue: 0.09))
    }
}

@MainActor
enum OrbPreviewRenderer {
    static func render() {
        let renderer = ImageRenderer(content: OrbGalleryView())
        renderer.scale = 2
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            NSLog("Hyperfocus: orb gallery render failed"); return
        }
        let url = dir.appendingPathComponent("orb_gallery.png")
        try? png.write(to: url)
        NSLog("Hyperfocus: orb gallery written to \(url.path)")
    }
}
#endif

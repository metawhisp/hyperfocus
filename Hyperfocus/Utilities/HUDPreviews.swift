// HUDPreviews.swift — DEBUG-only live gallery (HF_HUD_PREVIEW=1) of session progress-bar variants.
// User feedback on the shipped bar: the black dot on the fill is superfluous, the empty bar looks
// dead (needs motion in the dark zone), and the % label should appear from 30%, not 10%.
// Six replacements below; each loops 0→100% (2 s idle hold at the start so the dark-zone motion
// is visible) with the burn palette (lime → amber @70% → red @85%). Preview-before-prod.

#if DEBUG
import SwiftUI
import AppKit

// MARK: Shared pieces

private let BAR_W: CGFloat = 400
private let BAR_H: CGFloat = 42

/// Burn palette — same math as production FDProgress (orb green #29EB8C, one green everywhere).
private func burnColor(_ f: CGFloat) -> Color {
    func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ t: Double) -> Color {
        Color(red: a.0 + (b.0 - a.0) * t, green: a.1 + (b.1 - a.1) * t, blue: a.2 + (b.2 - a.2) * t)
    }
    let green = (0.16, 0.92, 0.55), amber = (1.0, 0.62, 0.18), red = (1.0, 0.30, 0.28)
    if f < 0.70 { return mix(green, green, 0) }
    if f < 0.85 { return mix(green, amber, Double((f - 0.70) / 0.15)) }
    return mix(amber, red, Double(min(1, (f - 0.85) / 0.15)))
}

/// 16 s audition cycle: hold empty 2 s → fill over 11 s → hold full 3 s.
private func loopFraction(_ t: Double) -> CGFloat {
    let u = t.truncatingRemainder(dividingBy: 16)
    if u < 2 { return 0 }
    if u < 13 { return CGFloat((u - 2) / 11) }
    return 1
}

/// The % label, black over the fill — appears from 30% (user-picked threshold).
private struct PctLabel: View {
    let f: CGFloat
    var body: some View {
        if f >= 0.30 {
            Text("\(Int(f * 100))%")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(.black.opacity(0.75))
                .padding(.trailing, 12)
        }
    }
}

private struct Track: View {
    var body: some View {
        Capsule().fill(Color.black.opacity(0.35))
    }
}

private func fillWidth(_ f: CGFloat) -> CGFloat { max(14, f * BAR_W) }

private struct Fill: View {
    let f: CGFloat
    var body: some View {
        let color = burnColor(f)
        Capsule()
            .fill(LinearGradient(colors: [color, color.opacity(0.75)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(width: fillWidth(f))
            .shadow(color: color.opacity(0.8), radius: 12)
            .shadow(color: color.opacity(0.45), radius: 30)
    }
}

// MARK: A — CLEAN · SCAN: no head ornament; a soft highlight sweeps the dark zone

private struct BarClean: View {
    let t: Double
    var body: some View {
        let f = loopFraction(t)
        ZStack(alignment: .leading) {
            Track()
            // The sweep lives UNDER the fill — visible only in the dark zone.
            let x = (t * 140).truncatingRemainder(dividingBy: Double(BAR_W + 120)) - 60
            LinearGradient(colors: [.clear, .white.opacity(0.10), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 120)
                .offset(x: CGFloat(x))
                .clipShape(Capsule())
            Fill(f: f).overlay(alignment: .trailing) { PctLabel(f: f) }
        }
        .frame(width: BAR_W, height: BAR_H)
    }
}

// MARK: B — LED · SEGMENTS: hardware segment bar; head segment pulses, a faint runner
// chases through the dark segments

private struct BarSegments: View {
    let t: Double
    private let n = 28

    var body: some View {
        let f = loopFraction(t)
        let lit = Int(f * CGFloat(n))
        let runner = Int(t * 9) % n
        let color = burnColor(f)
        ZStack(alignment: .leading) {
            Track()
            HStack(spacing: 3.5) {
                ForEach(0..<n, id: \.self) { i in
                    let isLit = i < lit
                    let isHead = i == lit - 1 && f < 1
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(isLit ? color : .white.opacity(i == runner ? 0.16 : 0.05))
                        .opacity(isHead ? 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 7)) : 1)
                }
            }
            .frame(height: 20)
            .padding(.horizontal, 9)
            .shadow(color: color.opacity(f > 0 ? 0.55 : 0), radius: 10)
            if f >= 0.30 {
                Text("\(Int(f * 100))%")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.black.opacity(0.75))
                    .frame(width: fillWidth(f), alignment: .trailing)
                    .padding(.trailing, 12)
            }
        }
        .frame(width: BAR_W, height: BAR_H)
    }
}

// MARK: C — COMET: white-hot leading edge with a light trail; faint drifting sparks in the dark

private struct BarComet: View {
    let t: Double
    var body: some View {
        let f = loopFraction(t)
        ZStack(alignment: .leading) {
            Track()
            // Sparks drifting right in the dark zone.
            ForEach(0..<3, id: \.self) { i in
                let speed = 30.0 + Double(i) * 18
                let x = (t * speed + Double(i) * 140).truncatingRemainder(dividingBy: Double(BAR_W - 20)) + 10
                Circle().fill(.white.opacity(0.12))
                    .frame(width: 3, height: 3)
                    .offset(x: CGFloat(x))
            }
            Fill(f: f).overlay(alignment: .trailing) { PctLabel(f: f) }
            if f > 0.02 && f < 1 {
                // Comet head: hot core + trailing streak, breathing slightly.
                HStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .white.opacity(0.75)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: 36, height: 6)
                        .clipShape(Capsule())
                    Circle().fill(.white)
                        .frame(width: 9, height: 9)
                        .shadow(color: .white.opacity(0.9), radius: 6)
                }
                .opacity(0.75 + 0.25 * sin(t * 4))
                .offset(x: fillWidth(f) - 42)
            }
        }
        .frame(width: BAR_W, height: BAR_H)
    }
}

// MARK: D — CURSOR: terminal-style blinking caret at the head; the track itself breathes

private struct BarCursor: View {
    let t: Double
    var body: some View {
        let f = loopFraction(t)
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.32 + 0.06 * sin(t * 1.6)))
            Fill(f: f).overlay(alignment: .trailing) { PctLabel(f: f) }
            if f < 1 {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white)
                    .frame(width: 3.5, height: 24)
                    .shadow(color: burnColor(f).opacity(0.9), radius: 5)
                    .opacity(sin(t * 6) > 0 ? 0.95 : 0.15)   // hard terminal blink
                    .offset(x: fillWidth(f) + 5)
            }
        }
        .frame(width: BAR_W, height: BAR_H)
    }
}

// MARK: E — FLOW: diagonal stripes crawl through the fill AND (faintly) the dark zone —
// the whole bar reads alive with no head ornament at all

/// Diagonal moving stripes (shared by FLOW and the FLOW+RULER hybrid).
private func flowStripes(_ opacity: Double, phase: Double) -> some View {
    Canvas { ctx, size in
        let period: CGFloat = 16
        let shift = CGFloat(phase.truncatingRemainder(dividingBy: Double(period)))
        var x: CGFloat = -size.height - period + shift
        while x < size.width + period {
            var p = Path()
            p.move(to: CGPoint(x: x, y: size.height))
            p.addLine(to: CGPoint(x: x + size.height, y: 0))
            p.addLine(to: CGPoint(x: x + size.height + 6, y: 0))
            p.addLine(to: CGPoint(x: x + 6, y: size.height))
            p.closeSubpath()
            ctx.fill(p, with: .color(.white.opacity(opacity)))
            x += period
        }
    }
}

private struct BarFlow: View {
    let t: Double

    private func stripes(_ opacity: Double, phase: Double) -> some View {
        flowStripes(opacity, phase: phase)
    }

    var body: some View {
        let f = loopFraction(t)
        ZStack(alignment: .leading) {
            Track()
            stripes(0.035, phase: t * 10).clipShape(Capsule())
            Fill(f: f)
                .overlay(stripes(0.14, phase: t * 22).clipShape(Capsule()).frame(width: fillWidth(f)),
                         alignment: .leading)
                .overlay(alignment: .trailing) { PctLabel(f: f) }
        }
        .frame(width: BAR_W, height: BAR_H)
    }
}

// MARK: F — RULER: tick marks across the track glimmer in sequence; chevron head

private struct BarRuler: View {
    let t: Double
    var body: some View {
        let f = loopFraction(t)
        ZStack(alignment: .leading) {
            Track()
            HStack(spacing: 0) {
                ForEach(1..<10, id: \.self) { i in
                    let glim = (Int(t * 6) % 9) + 1 == i
                    Rectangle()
                        .fill(.white.opacity(glim ? 0.30 : 0.12))
                        .frame(width: 1.5, height: i == 5 ? 16 : 10)
                        .frame(width: BAR_W / 10)
                }
            }
            .offset(x: BAR_W / 20)
            Fill(f: f).overlay(alignment: .trailing) { PctLabel(f: f) }
            if f > 0.02 && f < 1 {
                Image(systemName: "chevron.compact.right")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(burnColor(f))
                    .shadow(color: burnColor(f).opacity(0.9), radius: 4)
                    .opacity(0.5 + 0.5 * sin(t * 5))
                    .offset(x: fillWidth(f) + 6)
            }
        }
        .frame(width: BAR_W, height: BAR_H)
    }
}

// MARK: G — FLOW + RULER hybrid: stripes crawl through the FILL, ruler ticks glimmer in the DARK

private struct BarFlowRuler: View {
    let t: Double
    var body: some View {
        let f = loopFraction(t)
        ZStack(alignment: .leading) {
            Track()
            // Dark zone: ruler ticks glimmering in sequence (the fill covers them as it grows).
            HStack(spacing: 0) {
                ForEach(1..<10, id: \.self) { i in
                    let glim = (Int(t * 6) % 9) + 1 == i
                    Rectangle()
                        .fill(.white.opacity(glim ? 0.30 : 0.12))
                        .frame(width: 1.5, height: i == 5 ? 16 : 10)
                        .frame(width: BAR_W / 10)
                }
            }
            .offset(x: BAR_W / 20)
            // Fill: flowing diagonal stripes.
            Fill(f: f)
                .overlay(flowStripes(0.14, phase: t * 22).clipShape(Capsule()).frame(width: fillWidth(f)),
                         alignment: .leading)
                .overlay(alignment: .trailing) { PctLabel(f: f) }
        }
        .frame(width: BAR_W, height: BAR_H)
    }
}

// MARK: Gallery

struct HUDProgressGalleryView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            VStack(spacing: 18) {
                Text("ПРОГРЕСС-БАР HUD — без чёрной точки, % с 30%, живая пустая зона")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))

                row("A · CLEAN + SCAN", "без носика; блик медленно сканирует тёмную зону") { BarClean(t: t) }
                row("B · LED SEGMENTS", "сегменты как на приборе; голова пульсирует, бегунок в темноте") { BarSegments(t: t) }
                row("C · COMET", "бело-горячая точка-комета с хвостом; искры дрейфуют в темноте") { BarComet(t: t) }
                row("D · CURSOR", "терминальный мигающий курсор на краю; трек дышит") { BarCursor(t: t) }
                row("E · FLOW", "диагональные полосы текут по заливке и еле заметно по темноте") { BarFlow(t: t) }
                row("F · RULER", "риски-деления мерцают по очереди; шеврон на краю") { BarRuler(t: t) }
                row("G · FLOW + RULER", "в заливке текут полосы, в темноте мерцают деления") { BarFlowRuler(t: t) }
            }
            .padding(24)
        }
        .frame(width: 470)
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
                Circle().fill(FD.lime.opacity(0.10)).frame(width: 180, height: 180)
                    .blur(radius: 70).offset(x: -50, y: -60)
            }
        )
        .preferredColorScheme(.dark)
    }

    private func row<V: View>(_ name: String, _ hint: String, @ViewBuilder bar: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(name).font(FD.matrix(12)).foregroundStyle(FD.lime)
                Text(hint).font(.system(size: 10)).foregroundStyle(FD.label)
            }
            bar()
        }
    }
}

@MainActor
enum HUDPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 470, height: 700),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — HUD Progress Gallery"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: HUDProgressGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

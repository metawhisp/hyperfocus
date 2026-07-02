// QuickStartPreviews.swift — DEBUG-only live gallery (HF_CHIPS_PREVIEW=1): five styles for the
// long-press quick-start chips around the orb. Current chips are flat gray pills (and the label
// even truncates to "15…") — user wants them sexy. Each cell loops the full interaction:
// chips appear around the idle orb → the highlight sweeps across them (simulating the drag) →
// the middle one gets picked → everything fades. Preview-before-prod.

#if DEBUG
import SwiftUI
import AppKit

private let MINUTES = [15, 25, 45]

/// One 5.2 s interaction loop shared by every variant.
private struct DemoPhase {
    let appear: [Double]     // 0…1 per chip, staggered
    let highlight: Int?      // which chip the "drag" is over
    let selectedFlash: Double // 0…1 pulse once the middle chip is picked
    let fade: Double         // 0…1 global fade-out at the end

    init(t: Double) {
        let u = t.truncatingRemainder(dividingBy: 5.2)
        appear = (0..<3).map { i in
            let s = 0.15 + Double(i) * 0.12
            return min(1, max(0, (u - s) / 0.35))
        }
        if u > 1.4 && u < 3.2 {
            highlight = Int((u - 1.4) / 0.6) % 3
        } else if u >= 3.2 && u < 4.4 {
            highlight = 1
        } else {
            highlight = nil
        }
        selectedFlash = u >= 3.4 && u < 4.0 ? 1 - abs((u - 3.4) / 0.6 * 2 - 1) : 0
        fade = min(1, max(0, (u - 4.4) / 0.5))
    }
    /// Springy overshoot for the appear phase.
    func pop(_ i: Int) -> Double {
        let p = appear[i]
        return p >= 1 ? 1 : 1.15 * p * p * (3 - 2 * p)
    }
}

/// The idle red orb every cell docks its chips around.
private struct DemoOrb: View {
    let t: Double
    var body: some View {
        RingToParticlesOrb(t: t, progress: 0, diameter: 40, brightness: 3.0)
            .frame(width: 76, height: 76)
    }
}

// Chip slots around the orb (cell is 440×230, orb at center).
private let SLOTS: [CGSize] = [CGSize(width: -128, height: 0),
                               CGSize(width: 128, height: 0),
                               CGSize(width: 0, height: 74)]

// MARK: A — MATRIX PODS: FD device pills, matrix digits, lime ignition on hover

private struct ChipsA: View {
    let t: Double
    var body: some View {
        let ph = DemoPhase(t: t)
        ZStack {
            DemoOrb(t: t)
            ForEach(0..<3, id: \.self) { i in
                let hot = ph.highlight == i
                let sel = i == 1 && ph.selectedFlash > 0
                HStack(spacing: 5) {
                    Text("\(MINUTES[i])").font(FD.matrix(17))
                        .foregroundStyle(sel || hot ? .black : .white)
                    Text("MIN").font(.system(size: 8, weight: .bold)).tracking(1)
                        .foregroundStyle(sel || hot ? .black.opacity(0.7) : FD.label)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(sel || hot ?
                    AnyShapeStyle(FD.limeGradient) :
                    AnyShapeStyle(LinearGradient(colors: [FD.deviceHi, FD.device],
                                                 startPoint: .top, endPoint: .bottom))))
                .overlay(Capsule().strokeBorder(hot || sel ? FD.lime : .white.opacity(0.10), lineWidth: 1))
                .shadow(color: hot || sel ? FD.lime.opacity(0.8) : .black.opacity(0.5), radius: hot ? 14 : 8, y: 3)
                .scaleEffect((hot ? 1.1 : 1) * ph.pop(i) * (sel ? 1 + ph.selectedFlash * 0.08 : 1))
                .offset(x: SLOTS[i].width * ph.pop(i), y: SLOTS[i].height * ph.pop(i))
                .opacity(ph.appear[i] * (1 - ph.fade))
            }
        }
    }
}

// MARK: B — ORBITALS: little round satellites flying out of the orb

private struct ChipsB: View {
    let t: Double
    var body: some View {
        let ph = DemoPhase(t: t)
        ZStack {
            DemoOrb(t: t)
            ForEach(0..<3, id: \.self) { i in
                let hot = ph.highlight == i
                let sel = i == 1 && ph.selectedFlash > 0
                VStack(spacing: 1) {
                    Text("\(MINUTES[i])").font(FD.matrix(16))
                        .foregroundStyle(sel ? .black : (hot ? FD.lime : .white))
                    Text("MIN").font(.system(size: 7, weight: .bold)).tracking(0.8)
                        .foregroundStyle(sel ? .black.opacity(0.7) : FD.label)
                }
                .frame(width: 52, height: 52)
                .background(Circle().fill(sel ? AnyShapeStyle(FD.limeGradient)
                                              : AnyShapeStyle(Color.black.opacity(0.55))))
                .overlay(Circle().strokeBorder(hot || sel ? FD.lime : .white.opacity(0.12),
                                               lineWidth: hot ? 2 : 1))
                .shadow(color: hot || sel ? FD.lime.opacity(0.8) : .black.opacity(0.5),
                        radius: hot ? 16 : 7)
                .scaleEffect(hot ? 1.14 : 1)
                .rotationEffect(.degrees((1 - ph.pop(i)) * -40))
                .offset(x: SLOTS[i].width * ph.pop(i), y: SLOTS[i].height * ph.pop(i))
                .opacity(ph.appear[i] * (1 - ph.fade))
            }
        }
    }
}

// MARK: C — FAN TAGS: angular tickets fanning out, the hot one lifts

private struct ChipsC: View {
    let t: Double
    var body: some View {
        let ph = DemoPhase(t: t)
        ZStack {
            DemoOrb(t: t)
            ForEach(0..<3, id: \.self) { i in
                let hot = ph.highlight == i
                let sel = i == 1 && ph.selectedFlash > 0
                let baseAngle: Double = [-8, 8, 0][i]
                HStack(spacing: 6) {
                    Rectangle().fill(hot || sel ? FD.lime : FD.label)
                        .frame(width: 3, height: 16)
                    Text("\(MINUTES[i])").font(FD.matrix(16))
                        .foregroundStyle(sel ? .black : .white)
                    Text("MIN").font(.system(size: 8, weight: .bold)).tracking(1)
                        .foregroundStyle(sel ? .black.opacity(0.7) : FD.label)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 6).fill(sel ?
                    AnyShapeStyle(FD.limeGradient) :
                    AnyShapeStyle(Color.black.opacity(0.55))))
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(hot || sel ? FD.lime.opacity(0.9) : .white.opacity(0.08), lineWidth: 1))
                .shadow(color: hot || sel ? FD.lime.opacity(0.7) : .black.opacity(0.5), radius: hot ? 13 : 6, y: 3)
                .rotationEffect(.degrees(baseAngle + (1 - ph.pop(i)) * -25))
                .scaleEffect(hot ? 1.1 : 1)
                .offset(x: SLOTS[i].width * ph.pop(i),
                        y: SLOTS[i].height * ph.pop(i) + (hot ? -5 : 0))
                .opacity(ph.appear[i] * (1 - ph.fade))
            }
        }
    }
}

// MARK: D — LED STACK: a hardware mini-menu drops under the orb, LEDs light on hover

private struct ChipsD: View {
    let t: Double
    var body: some View {
        let ph = DemoPhase(t: t)
        ZStack {
            DemoOrb(t: t).offset(y: -58)
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    row(i, ph: ph)
                }
            }
            .offset(y: 26)
        }
    }

    private func row(_ i: Int, ph: DemoPhase) -> some View {
        let hot = ph.highlight == i
        let sel = i == 1 && ph.selectedFlash > 0
        let ledColor: Color = hot || sel ? FD.lime : Color.white.opacity(0.18)
        let bg: AnyShapeStyle = sel
            ? AnyShapeStyle(FD.limeGradient)
            : AnyShapeStyle(Color.black.opacity(hot ? 0.65 : 0.45))
        let border: Color = hot || sel ? FD.lime.opacity(0.8) : Color.white.opacity(0.07)
        let numColor: Color = sel ? .black : .white
        let minColor: Color = sel ? Color.black.opacity(0.7) : FD.label

        return HStack(spacing: 10) {
            Circle().fill(ledColor)
                .frame(width: 6, height: 6)
                .shadow(color: hot || sel ? FD.lime.opacity(0.9) : .clear, radius: 5)
            Text("\(MINUTES[i])").font(FD.matrix(15)).foregroundStyle(numColor)
            Text("MIN").font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(minColor)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .frame(width: 118)
        .background(RoundedRectangle(cornerRadius: 9).fill(bg))
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(border, lineWidth: 1))
        .shadow(color: hot || sel ? FD.lime.opacity(0.55) : .clear, radius: 10)
        .offset(x: (1 - ph.pop(i)) * -18)
        .opacity(ph.appear[i] * (1 - ph.fade))
    }
}

// MARK: E — GHOST NUMBERS: no containers, just glowing matrix digits materializing

private struct ChipsE: View {
    let t: Double
    var body: some View {
        let ph = DemoPhase(t: t)
        ZStack {
            DemoOrb(t: t)
            ForEach(0..<3, id: \.self) { i in
                ghost(i, ph: ph)
            }
        }
    }

    private func ghost(_ i: Int, ph: DemoPhase) -> some View {
        let hot = ph.highlight == i
        let sel = i == 1 && ph.selectedFlash > 0
        let lit = hot || sel
        let digitColor: Color = lit ? FD.lime : Color.white.opacity(0.9)
        let hotScale: CGFloat = hot ? 1.15 : 1
        let popScale: CGFloat = CGFloat(0.6 + 0.4 * ph.pop(i))
        let selScale: CGFloat = sel ? CGFloat(1 + ph.selectedFlash * 0.1) : 1
        let pop = CGFloat(ph.pop(i))

        return VStack(spacing: 3) {
            Text("\(MINUTES[i])").font(FD.matrix(26))
                .foregroundStyle(digitColor)
                .shadow(color: FD.lime.opacity(lit ? 1.0 : 0.35), radius: hot ? 18 : 8)
            Text("MIN").font(.system(size: 8, weight: .bold)).tracking(1.6)
                .foregroundStyle(FD.label)
            Rectangle().fill(FD.lime)
                .frame(width: lit ? 34 : 0, height: 2)
                .shadow(color: FD.lime.opacity(0.9), radius: 4)
                .animation(.easeOut(duration: 0.15), value: hot)
        }
        .scaleEffect(hotScale * popScale * selScale)
        .blur(radius: CGFloat(1 - ph.appear[i]) * 6)
        .offset(x: SLOTS[i].width * pop, y: SLOTS[i].height * pop)
        .opacity(ph.appear[i] * (1 - ph.fade))
    }
}

// MARK: Gallery

struct QuickStartGalleryView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            VStack(spacing: 14) {
                Text("QUICK-START ЧИПЫ — 5 вариантов, цикл: появление → драг-подсветка → выбор")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                Grid(horizontalSpacing: 14, verticalSpacing: 14) {
                    GridRow {
                        cell("A · MATRIX PODS", "приборные капсулы, лайм зажигается под курсором") { ChipsA(t: t) }
                        cell("B · ORBITALS", "спутники вылетают из орба по дуге") { ChipsB(t: t) }
                    }
                    GridRow {
                        cell("C · FAN TAGS", "веер угловых ярлыков, горячий приподнимается") { ChipsC(t: t) }
                        cell("D · LED STACK", "мини-меню прибора под орбом, LED загорается") { ChipsD(t: t) }
                    }
                    GridRow {
                        cell("E · GHOST NUMBERS", "просто светящиеся цифры, без контейнеров") { ChipsE(t: t) }
                        Color.clear.frame(width: 440, height: 250)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func cell<V: View>(_ name: String, _ hint: String, @ViewBuilder v: () -> V) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [FD.deviceHi.opacity(0.6), FD.device],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.06), lineWidth: 1)
                v()
            }
            .frame(width: 440, height: 220)
            HStack(spacing: 8) {
                Text(name).font(.system(size: 11, weight: .bold)).foregroundStyle(FD.lime)
                Text(hint).font(.system(size: 11)).foregroundStyle(FD.label)
            }
        }
    }
}

@MainActor
enum QuickStartPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 950, height: 840),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Quick-Start Chips Gallery"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: QuickStartGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

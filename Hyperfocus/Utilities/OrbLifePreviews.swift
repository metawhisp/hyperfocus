// OrbLifePreviews.swift — DEBUG-only live gallery (HF_ORB_LIFE_PREVIEW=1): the idle (red) orb's
// "liveliness" animations. Six little moments the waiting orb comes alive (eyes, wink, spin,
// pulse, tilt, orbit-out) plus the ONE entrance it plays when summoned from the menu.
//
// Production model (shown by the PROD SIMULATION hero at the top):
//   • Entrance = the SPIN animation, ONCE, only when "Show Focus Orb" is picked from the menu.
//   • Liveliness = a RANDOM one of the six, at RANDOM times (~every 30–60 min in prod).
// The six labelled cells below just loop each beat so it can be judged. Preview-before-prod.

#if DEBUG
import SwiftUI
import AppKit

private let RED = RingToParticlesOrb.offRGB   // every variant stays on the idle red

private extension OrbLifeVariant {
    var title: String {
        switch self {
        case .blink: return "A · BLINK"
        case .spin:  return "B · SPIN"
        case .gaze:  return "C · GAZE"
        case .pulse: return "D · PULSE"
        case .tilt:  return "E · TILT + WINK"
        case .orbit: return "F · ROLL-OUT"
        }
    }
    var hint: String {
        switch self {
        case .blink: return "моргает и подмигивает"
        case .spin:  return "раскручивается в сферу и назад"
        case .gaze:  return "с любопытством озирается"
        case .pulse: return "двойной удар сердца — свечение"
        case .tilt:  return "наклоняет «голову», подмигивает"
        case .orbit: return "перекатывается вбок и возвращается"
        }
    }
}

// MARK: The idle orb + one optional life-beat — renders from the SHARED OrbLifeFrame (Orb/OrbLife.swift)

/// `lt` (seconds-into-beat) non-nil → play the variant's expression. `entering` adds the
/// summon spring-scale (hero/entrance only). Slide is scaled to this preview's larger frame.
private struct OrbLifeView: View {
    let variant: OrbLifeVariant
    let lt: Double?
    var d: CGFloat = 54
    var t: Double = 0
    var dir: Double = 1
    var entering: Double = 1

    var body: some View {
        let f = lt != nil ? OrbLifeFrame.compute(variant, elapsed: lt!, dir: dir) : OrbLifeFrame()
        ZStack {
            RingToParticlesOrb(t: t, progress: f.progress, diameter: d,
                               brightness: 3.0 * f.brightnessMul, rgbOverride: RED)
                .frame(width: d * 2.4, height: d * 2.4)
            if f.eyeFade > 0 {
                OrbEyes(d: d, leftOpen: f.leftOpen, rightOpen: f.rightOpen, gaze: f.gaze)
                    .opacity(f.eyeFade)
            }
        }
        .rotationEffect(.degrees(f.rotationDeg))
        .offset(x: f.slideNorm * d * 0.5)     // preview has room for a big roll
        .scaleEffect(entering * f.scale)
        .opacity(entering < 0.05 ? 0 : 1)
    }
}

// MARK: PROD SIMULATION hero — spin entrance once, then random beats at random times

private struct ProdSimHero: View {
    let t: Double
    private let cycle = 40.0

    var body: some View {
        let u = t.truncatingRemainder(dividingBy: cycle)
        // 0–2 s: the SPIN summon entrance (scale-in + spin). Then random idle beats.
        let content: OrbLifeView = {
            if u < 2.0 {
                let enter = min(1, u / 0.6)
                let overshoot = enter < 1 ? 0.3 + 0.85 * (enter * enter * (3 - 2 * enter)) : 1
                return OrbLifeView(variant: .spin, lt: u, d: 70, t: t, entering: overshoot)
            }
            let idle = u - 2.0
            let slotLen = 5.5
            let slot = Int(idle / slotLen)
            let local = idle - Double(slot) * slotLen
            let v = OrbLifeVariant(rawValue: (slot * 7 + 2) % OrbLifeVariant.allCases.count)!
            let active = local < v.duration
            return OrbLifeView(variant: v, lt: active ? local : nil, d: 70, t: t, entering: 1)
        }()
        content
    }
}

// MARK: Gallery

struct OrbLifeGalleryView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            VStack(spacing: 14) {
                Text("ЖИВОЙ ОРБ — появление (спин, 1 раз из меню) + 6 случайных «искр жизни»")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.85))

                heroPanel(t)

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        ForEach([OrbLifeVariant.blink, .spin, .gaze], id: \.self) { cell($0, t) }
                    }
                    GridRow {
                        ForEach([OrbLifeVariant.pulse, .tilt, .orbit], id: \.self) { cell($0, t) }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func heroPanel(_ t: Double) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [FD.deviceHi.opacity(0.6), .black],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 16).strokeBorder(FD.lime.opacity(0.25), lineWidth: 1)
                ProdSimHero(t: t)
            }
            .frame(width: 760, height: 210).clipped()
            Text("ПРОД: появление спином один раз (Show Focus Orb) → дальше случайные искры в случайное время")
                .font(.system(size: 10, weight: .semibold)).foregroundStyle(FD.lime)
        }
    }

    private func cell(_ v: OrbLifeVariant, _ t: Double) -> some View {
        // Each reference cell loops its beat every 5 s so it can be judged (no entrance).
        let period = v.duration + 2.6
        let u = t.truncatingRemainder(dividingBy: period)
        let lt: Double? = u < v.duration ? u : nil
        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [FD.deviceHi.opacity(0.4), .black],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.06), lineWidth: 1)
                OrbLifeView(variant: v, lt: lt, d: 50, t: t, entering: 1)
            }
            .frame(width: 244, height: 150).clipped()
            VStack(spacing: 1) {
                Text(v.title).font(.system(size: 11, weight: .bold)).foregroundStyle(FD.lime)
                Text(v.hint).font(.system(size: 10)).foregroundStyle(FD.label)
            }
        }
    }
}

@MainActor
enum OrbLifePreviewWindow {
    private static var window: NSWindow?
    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 820, height: 640),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Living Orb Gallery"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: OrbLifeGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

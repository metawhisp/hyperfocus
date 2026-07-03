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

enum LifeVariant: Int, CaseIterable {
    case blink, spin, gaze, pulse, tilt, orbit
    var title: String {
        switch self {
        case .blink: return "A · BLINK"
        case .spin:  return "B · SPIN"
        case .gaze:  return "C · GAZE"
        case .pulse: return "D · PULSE"
        case .tilt:  return "E · TILT + WINK"
        case .orbit: return "F · ORBIT-OUT"
        }
    }
    var hint: String {
        switch self {
        case .blink: return "моргает и подмигивает"
        case .spin:  return "раскручивается в сферу и назад"
        case .gaze:  return "с любопытством озирается"
        case .pulse: return "двойной удар сердца — свечение"
        case .tilt:  return "наклоняет «голову», подмигивает"
        case .orbit: return "крутится и отъезжает вбок, возвращается"
        }
    }
    /// Beat length in seconds.
    var duration: Double {
        switch self {
        case .blink, .gaze, .tilt: return 2.2
        case .spin, .pulse:        return 1.8
        case .orbit:               return 2.6
        }
    }
}

// MARK: The idle orb + one optional life-beat

/// Renders the red idle orb; if `lt` (seconds-into-beat) is non-nil, overlays the variant's
/// expression. `entering` adds the summon spring-scale (only the hero/entrance uses it).
private struct OrbLifeView: View {
    let variant: LifeVariant
    let lt: Double?
    var d: CGFloat = 54
    var t: Double = 0
    var entering: Double = 1     // 0…1 entrance scale factor input

    var body: some View {
        let active = lt != nil
        let p = lt ?? 0
        let dur = variant.duration
        let env = active ? sin(min(1, p / dur) * .pi) : 0     // 0→1→0 across the beat

        // spin / orbit inflate the ring to a red sphere; others stay a ring.
        let prog = (variant == .spin || variant == .orbit) ? 0.92 * env : 0
        let spinRot = t * (1 + 6 * env * (variant == .spin || variant == .orbit ? 1 : 0))
        let bright = 3.0 + (variant == .pulse ? 1.7 * pulseEnv(p, active) : 0)

        // orbit slides out along x and back; direction seeded so it varies.
        let slide = variant == .orbit ? sin(env * .pi) * d * 0.5 * orbitDir : 0
        // tilt cocks the whole head.
        let tilt = variant == .tilt ? sin(env * .pi * 2) * 13 * env : 0
        // pulse gives a little size bump.
        let bump = variant == .pulse ? 0.12 * pulseEnv(p, active) : 0

        ZStack {
            RingToParticlesOrb(t: spinRot, progress: prog, diameter: d,
                               brightness: bright, rgbOverride: RED)
                .frame(width: d * 2.4, height: d * 2.4)
            if hasEyes {
                eyes(env: env, p: p, active: active)
            }
        }
        .rotationEffect(.degrees(tilt))
        .offset(x: slide)
        .scaleEffect(entering * (1 + bump))
        .opacity(entering < 0.05 ? 0 : 1)
    }

    private var hasEyes: Bool { variant == .blink || variant == .gaze || variant == .tilt }
    private var orbitDir: Double { 1 }   // preview: consistent right; prod randomizes

    private func pulseEnv(_ p: Double, _ active: Bool) -> Double {
        guard active else { return 0 }
        // two quick bumps at ~0.5s and ~0.9s
        return max(bump(p, 0.5, 0.18), bump(p, 0.95, 0.18))
    }
    private func bump(_ p: Double, _ c: Double, _ w: Double) -> Double {
        let x = abs(p - c) / w
        return x >= 1 ? 0 : 1 - x
    }

    @ViewBuilder
    private func eyes(env: Double, p: Double, active: Bool) -> some View {
        let fade = active ? min(1, env * 2.2) : 0        // eyes fade in/out with the beat
        let blink = variant == .blink ? bump(p, 1.0, 0.14) : 0
        let wink  = variant == .blink ? bump(p, 1.6, 0.16)
                  : variant == .tilt  ? bump(p, 1.4, 0.18) : 0
        let gaze  = variant == .gaze ? sin((p / variant.duration) * .pi * 2) : 0
        let gBlink = variant == .gaze ? bump(p, 1.9, 0.14) : 0
        OrbEyes(d: d,
                leftOpen: (1 - max(blink, gBlink)) * fade,
                rightOpen: (1 - max(blink, wink, gBlink)) * fade,
                gaze: gaze)
            .opacity(fade)
    }
}

/// Two eyes in the orb's hollow centre.
private struct OrbEyes: View {
    let d: CGFloat
    var leftOpen: Double = 1
    var rightOpen: Double = 1
    var gaze: Double = 0

    var body: some View {
        let eyeW = d * 0.11
        let eyeH = d * 0.22
        HStack(spacing: d * 0.16) {
            eye(open: leftOpen, w: eyeW, h: eyeH)
            eye(open: rightOpen, w: eyeW, h: eyeH)
        }
        .offset(x: gaze * d * 0.05)
    }
    private func eye(open: Double, w: CGFloat, h: CGFloat) -> some View {
        Capsule().fill(.white)
            .frame(width: w, height: max(w * 0.45, h * open))
            .shadow(color: .white.opacity(0.5), radius: 2)
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
            let v = LifeVariant(rawValue: (slot * 7 + 2) % LifeVariant.allCases.count)!
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
                        ForEach([LifeVariant.blink, .spin, .gaze], id: \.self) { cell($0, t) }
                    }
                    GridRow {
                        ForEach([LifeVariant.pulse, .tilt, .orbit], id: \.self) { cell($0, t) }
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

    private func cell(_ v: LifeVariant, _ t: Double) -> some View {
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

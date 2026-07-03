// OrbLifePreviews.swift — DEBUG-only live gallery (HF_ORB_LIFE_PREVIEW=1): five minimalist
// "liveliness" animations for the IDLE (red) orb — the little moments it comes alive while
// waiting (eyes, wink, spin, pulse, tilt), plus the entrance it plays when summoned from the
// menu's "Show Focus Orb". Each cell loops: appear → calm wait → one life-beat → calm.
// Preview-before-prod. In production these fire rarely (~every 30–60 min) so they stay a delight.

#if DEBUG
import SwiftUI
import AppKit

private let RED = RingToParticlesOrb.offRGB   // keep every variant on the idle red

/// Shared loop timing over an 8 s cycle.
private struct Beat {
    let appear: Double     // 0…1 entrance progress (first ~0.8 s)
    let u: Double          // seconds within the cycle
    init(_ t: Double) {
        u = t.truncatingRemainder(dividingBy: 8)
        appear = min(1, u / 0.7)
    }
    /// Springy entrance scale (overshoot then settle).
    var entranceScale: Double {
        guard appear < 1 else { return 1 }
        let p = appear
        return 0.2 + (1.15 - 0.2) * (p * p * (3 - 2 * p))
    }
    /// A life-beat window [start, start+dur] → 0…1 triangular envelope.
    func window(_ start: Double, _ dur: Double) -> Double {
        guard u >= start, u <= start + dur else { return 0 }
        let x = (u - start) / dur
        return 1 - abs(x * 2 - 1)
    }
}

/// Two eyes in the orb's hollow center: per-eye open amount (0 shut … 1 open) + gaze offset.
private struct OrbEyes: View {
    let d: CGFloat
    var leftOpen: Double = 1
    var rightOpen: Double = 1
    var gaze: Double = 0        // -1 left … 1 right

    var body: some View {
        let eyeW = d * 0.11
        let eyeH = d * 0.22
        let gap = d * 0.16
        HStack(spacing: gap) {
            eye(open: leftOpen, w: eyeW, h: eyeH)
            eye(open: rightOpen, w: eyeW, h: eyeH)
        }
        .offset(x: gaze * d * 0.05)
    }

    private func eye(open: Double, w: CGFloat, h: CGFloat) -> some View {
        Capsule().fill(.white)
            .frame(width: w, height: max(w * 0.5, h * open))
            .shadow(color: .white.opacity(0.5), radius: 2)
    }
}

// MARK: A — BLINK: two eyes, an occasional blink, then a wink

private struct LifeBlink: View {
    let t: Double
    var body: some View {
        let b = Beat(t)
        let blink = b.window(3.0, 0.25)              // full blink
        let wink = b.window(5.0, 0.3)                // right-eye wink
        let left = 1 - blink
        let right = 1 - max(blink, wink)
        base(b) {
            OrbEyes(d: 54, leftOpen: left, rightOpen: right)
        }
    }
}

// MARK: B — SPIN: the ring inflates into a red sphere, twirls, collapses back

private struct LifeSpin: View {
    let t: Double
    var body: some View {
        let b = Beat(t)
        let spin = b.window(3.0, 1.8)
        // progress 0 (ring) → up to ~0.9 (sphere) during the beat; extra rotation while spun.
        let prog = 0.9 * spin
        let rot = t * (1 + 6 * spin)
        Orb(diameter: 54, t: rot, progress: prog)
            .scaleEffect(b.entranceScale)
            .opacity(min(1, b.appear))
    }
}

// MARK: C — GAZE: eyes that curiously look around, then blink

private struct LifeGaze: View {
    let t: Double
    var body: some View {
        let b = Beat(t)
        let look = b.window(2.6, 2.2)
        let gaze = sin(look * .pi * 2) * look        // sweep right→left→center
        let blink = b.window(5.2, 0.22)
        base(b) {
            OrbEyes(d: 54, leftOpen: 1 - blink, rightOpen: 1 - blink, gaze: gaze)
        }
    }
}

// MARK: D — PULSE: a soft double heartbeat of glow + scale

private struct LifePulse: View {
    let t: Double
    var body: some View {
        let b = Beat(t)
        let p1 = b.window(3.0, 0.35)
        let p2 = b.window(3.5, 0.35)
        let beat = max(p1, p2)
        Orb(diameter: 54, t: t, progress: 0, brightness: 3.0 + 1.6 * beat)
            .scaleEffect(b.entranceScale * (1 + 0.12 * beat))
            .opacity(min(1, b.appear))
    }
}

// MARK: E — TILT + WINK: the orb cocks like a curious head and winks

private struct LifeTilt: View {
    let t: Double
    var body: some View {
        let b = Beat(t)
        let tilt = b.window(2.8, 2.0)
        let angle = sin(tilt * .pi * 2) * 12 * tilt
        let wink = b.window(4.6, 0.3)
        base(b) {
            OrbEyes(d: 54, leftOpen: 1, rightOpen: 1 - wink)
        }
        .rotationEffect(.degrees(angle))
    }
}

// MARK: Shared orb + face composition

private struct Orb: View {
    var diameter: CGFloat = 54
    var t: Double
    var progress: Double
    var brightness: Double = 3.0
    var body: some View {
        RingToParticlesOrb(t: t, progress: progress, diameter: diameter,
                           brightness: brightness, rgbOverride: RED)
            .frame(width: diameter * 2.2, height: diameter * 2.2)
    }
}

/// Red idle orb with an eyes overlay, sharing the springy entrance.
@ViewBuilder
private func base<Face: View>(_ b: Beat, @ViewBuilder face: () -> Face) -> some View {
    ZStack {
        Orb(diameter: 54, t: 0, progress: 0)
        face()
    }
    .scaleEffect(b.entranceScale)
    .opacity(min(1, b.appear))
}

// MARK: Gallery

struct OrbLifeGalleryView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            VStack(spacing: 14) {
                Text("ЖИВОЙ ОРБ — 5 вариантов ожидания + появление по «Show Focus Orb»")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                Text("цикл: появление → покой → одна «искра жизни» → покой (в проде — раз в 30–60 мин)")
                    .font(.system(size: 10)).foregroundStyle(FD.label)
                Grid(horizontalSpacing: 14, verticalSpacing: 14) {
                    GridRow {
                        cell("A · BLINK", "моргает и подмигивает") { LifeBlink(t: t) }
                        cell("B · SPIN", "раскручивается в сферу и обратно") { LifeSpin(t: t) }
                        cell("C · GAZE", "с любопытством озирается") { LifeGaze(t: t) }
                    }
                    GridRow {
                        cell("D · PULSE", "двойной удар сердца — свечение") { LifePulse(t: t) }
                        cell("E · TILT + WINK", "наклоняет «голову» и подмигивает") { LifeTilt(t: t) }
                        Color.clear.frame(width: 240, height: 210)
                    }
                }
            }
            .padding(22)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func cell<V: View>(_ name: String, _ hint: String, @ViewBuilder v: () -> V) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [FD.deviceHi.opacity(0.5), Color.black],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.06), lineWidth: 1)
                v()
            }
            .frame(width: 240, height: 180).clipped()
            VStack(spacing: 1) {
                Text(name).font(.system(size: 11, weight: .bold)).foregroundStyle(FD.lime)
                Text(hint).font(.system(size: 10)).foregroundStyle(FD.label)
            }
        }
    }
}

@MainActor
enum OrbLifePreviewWindow {
    private static var window: NSWindow?
    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 820, height: 560),
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

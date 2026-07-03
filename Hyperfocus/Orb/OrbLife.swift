// OrbLife.swift — the idle orb's "liveliness" beats (canon #39): the little moments the red
// waiting orb comes alive (eyes, wink, spin, pulse, tilt, roll). Pure, shared source of truth —
// both the production orb (FocusOrbView) and the DEBUG gallery render from OrbLifeFrame, so what
// you preview is exactly what ships.

import SwiftUI

enum OrbLifeVariant: Int, CaseIterable {
    case blink, spin, gaze, pulse, tilt, orbit

    /// Beat length in seconds.
    var duration: Double {
        switch self {
        case .blink, .gaze, .tilt: return 2.2
        case .spin, .pulse:        return 1.8
        case .orbit:               return 2.6
        }
    }
    var hasEyes: Bool { self == .blink || self == .gaze || self == .tilt }
}

/// Per-frame transform + expression for a beat. Normalised where it can be (slideNorm ∈ −1…1);
/// the consumer picks the pixel amplitude that fits its window.
struct OrbLifeFrame {
    var progress: Double = 0        // ring→sphere inflate (spin only)
    var brightnessMul: Double = 1
    var slideNorm: Double = 0       // −1…1, scaled to pixels by the consumer
    var rotationDeg: Double = 0     // tilt + roll
    var scale: Double = 1
    var eyeFade: Double = 0         // 0 = no eyes
    var leftOpen: Double = 1
    var rightOpen: Double = 1
    var gaze: Double = 0            // −1…1

    /// `elapsed` = seconds into the beat; `dir` = ±1 roll direction (orbit).
    static func compute(_ v: OrbLifeVariant, elapsed p: Double, dir: Double) -> OrbLifeFrame {
        let dur = v.duration
        let env = sin(min(1, max(0, p / dur)) * .pi)     // 0→1→0 across the beat
        var f = OrbLifeFrame()

        switch v {
        case .spin:
            f.progress = 0.92 * env        // ring inflates into a red sphere and back (the "orb" moment)
        case .pulse:
            let e = max(bump(p, 0.5, 0.18), bump(p, 0.95, 0.18))
            f.brightnessMul = 1 + 0.55 * e
            f.scale = 1 + 0.12 * e
        case .orbit:
            f.slideNorm = sin(env * .pi) * dir           // out and back
            f.rotationDeg = f.slideNorm * 120            // rolls like a wheel (no sphere spin)
        case .tilt:
            f.rotationDeg = sin(env * .pi * 2) * 13 * env
        case .blink, .gaze:
            break
        }

        if v.hasEyes {
            let fade = min(1, env * 2.2)
            let blink = v == .blink ? bump(p, 1.0, 0.14) : 0
            let wink  = v == .blink ? bump(p, 1.6, 0.16)
                      : v == .tilt  ? bump(p, 1.4, 0.18) : 0
            let gBlink = v == .gaze ? bump(p, 1.9, 0.14) : 0
            f.eyeFade = fade
            f.leftOpen = (1 - max(blink, gBlink)) * fade
            f.rightOpen = (1 - max(blink, wink, gBlink)) * fade
            f.gaze = v == .gaze ? sin((p / dur) * .pi * 2) : 0
        }
        return f
    }

    private static func bump(_ p: Double, _ c: Double, _ w: Double) -> Double {
        let x = abs(p - c) / w
        return x >= 1 ? 0 : 1 - x
    }
}

/// Two eyes in the orb's hollow centre, sized to the dot diameter.
struct OrbEyes: View {
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

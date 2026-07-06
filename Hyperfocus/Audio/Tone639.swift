// Tone639.swift — the 639 Hz focus tone with an immersive entrance (canon #29/#31).
// A viral "focus frequency" people find calming; we make NO medical claims (see FocusSoundMode).
// The tone doesn't just switch on — it ARRIVES: the pitch rises and LOCKS onto 639 Hz, then the
// pure tone flows out of that entrance (the SAME oscillator, no seam) and holds for the session.
// Two entrances:
//   • glide — one continuous oscillator eases up from two octaves below and settles on 639
//   • rise  — a consonant six-step ladder climbs, louder each step, and locks on 639
// Session-relative time drives the shape, so an away trip never replays the entrance.

import Foundation

final class Tone639Renderer {
    enum Entrance { case glide, rise }

    private let entrance: Entrance
    private let sr: Double
    private let twoPi = 2.0 * Double.pi
    private let f = 639.0

    // Phase accumulators, wrapped independently so partials stay precise over a long session.
    private var phF = 0.0, phSub = 0.0, phOct = 0.0, phBedA = 0.0, phBedB = 0.0

    // rise ladder: subharmonic ratios of 639 → a consonant climb that resolves ON 639.
    private let steps: [Double] = [213.0, 255.6, 319.5, 383.4, 511.2, 639.0]   // 639×[1/3,2/5,1/2,3/5,4/5,1]
    private let stepDur = 0.82
    private var tSteps: Double { Double(steps.count) * stepDur }                // ~4.9 s
    private let glideDur = 6.5

    /// RMS-match to the other soundscapes (raw ≈ 0.18) so switching sounds never jumps in level.
    private let masterScale: Float = 0.42

    init(entrance: Entrance, sampleRate: Double) {
        self.entrance = entrance
        sr = sampleRate
    }

    func render(t: Double) -> (left: Float, right: Float) {
        // 1) Current fundamental — the entrance shapes it, then it holds at 639.
        let curF: Double
        switch entrance {
        case .glide:
            if t < glideDur {
                let p = t / glideDur
                let pe = 1.0 - (1.0 - p) * (1.0 - p)          // ease-out: decelerates INTO the lock
                curF = (f / 4.0) * pow(f / (f / 4.0), pe)
            } else { curF = f }
        case .rise:
            if t < tSteps {
                curF = steps[min(steps.count - 1, Int(t / stepDur))]
            } else { curF = f }
        }

        // 2) Phase-continuous oscillators at the current fundamental (no click when curF jumps).
        phF = wrap(phF + twoPi * curF / sr)
        phSub = wrap(phSub + twoPi * (curF / 2) / sr)
        phOct = wrap(phOct + twoPi * (curF * 2) / sr)
        let fund = Float(sin(phF))

        let lockT = (entrance == .glide) ? glideDur : tSteps

        // 3) Amplitude — the entrance's crescendo, then a steady hold.
        let amp = amplitude(t: t, lockT: lockT)

        // 4) Warmth (sub-octave + faint 2nd) BLOOMS in around the lock — the tone thickens gently
        //    instead of a second layer cutting in.
        let warmth = Float(clamp01((t - (lockT - 0.5)) / 3.5))
        let partials = (Float(sin(phSub)) * 0.20 + Float(sin(phOct)) * 0.03) * warmth

        // 5) Slow breath begins only after the lock.
        var breath: Float = 1
        if t > lockT {
            let bl = Float(clamp01((t - lockT) / 3.0))
            breath = 1 - 0.10 * bl + 0.10 * bl * Float(sin(twoPi * 0.06 * t))
        }

        // 6) A low bed under the climb that fades out after the lock — then only the tone remains.
        let bed = bedSample(t: t, lockT: lockT)

        let s = ((fund * 0.6 + partials) * amp * breath + bed) * masterScale
        return (s, s)
    }

    // MARK: shape helpers

    private func amplitude(t: Double, lockT: Double) -> Float {
        let attack = Float(clamp01(t / 0.3))                  // kills the engine-start click
        switch entrance {
        case .glide:
            let swell = Float(0.35 + 0.65 * clamp01(t / glideDur))   // loudness rises with the pitch
            return swell * attack
        case .rise:
            if t >= tSteps { return attack }                 // sustain
            let idx = Int(t / stepDur)
            let lt = t - Double(idx) * stepDur               // time within this step
            let lvl = Float(0.28 + 0.72 * Double(idx) / Double(steps.count - 1))   // crescendo
            let last = idx == steps.count - 1
            let e: Float
            if lt < 0.09 { e = Float(lt / 0.09) }            // attack
            else if last { e = 1 }                           // final step holds into the sustain
            else if lt < 0.62 { e = 1 }
            else { e = 1 - 0.75 * Float((lt - 0.62) / 0.20) }   // dip toward the next step (not to 0)
            return e * lvl * attack
        }
    }

    private func bedSample(t: Double, lockT: Double) -> Float {
        guard t < lockT + 1.5 else { return 0 }
        var swell = Float(clamp01(t / lockT))
        if t > lockT { swell *= Float(max(0, 1 - (t - lockT) / 1.5)) }
        phBedA = wrap(phBedA + twoPi * (f / 6) / sr)         // 106.5 Hz
        if entrance == .rise {
            phBedB = wrap(phBedB + twoPi * (f / 3) / sr)     // 213 Hz — a touch more body under the ladder
            return (Float(sin(phBedA)) * 0.16 + Float(sin(phBedB)) * 0.08) * swell
        }
        return Float(sin(phBedA)) * 0.12 * swell
    }

    private func wrap(_ p: Double) -> Double { p > twoPi ? p - twoPi : p }
    private func clamp01(_ x: Double) -> Double { max(0, min(1, x)) }
}

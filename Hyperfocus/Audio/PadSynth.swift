// PadSynth.swift — our own generated ambient pad (canon #29): the production focus sound.
// Built the way real ambient pads are made (no samples, no noise): an A/E chord where every
// note is a 3-voice unison detune stack (±0.27% → slow chorus beating) plus a soft octave
// partial for brightness, breathing on slow LFOs at mutually unrelated rates, glued into
// music by a Freeverb-style reverb. Keeps the 220 Hz L / 260 Hz R pair (40 Hz interaural
// offset) measured in the reference track's spectrum.

import Foundation

struct PadNote {
    let freq: Double
    let ampL: Float
    let ampR: Float
    let lfoRate: Double     // slow, mutually unrelated → the texture never repeats
    let lfoPhase: Double
}

enum PadBank {
    // A/E chord; A3-left / ~C4-right keeps the 40 Hz interaural offset from the reference.
    static let notes: [PadNote] = [
        PadNote(freq: 110.00, ampL: 0.45, ampR: 0.45, lfoRate: 0.013, lfoPhase: 0.0),   // A2
        PadNote(freq: 164.81, ampL: 0.35, ampR: 0.35, lfoRate: 0.019, lfoPhase: 1.7),   // E3
        PadNote(freq: 220.00, ampL: 0.42, ampR: 0.18, lfoRate: 0.027, lfoPhase: 3.9),   // A3 → L
        PadNote(freq: 260.00, ampL: 0.18, ampR: 0.42, lfoRate: 0.023, lfoPhase: 2.6),   // ~C4 → R
        PadNote(freq: 329.63, ampL: 0.16, ampR: 0.16, lfoRate: 0.041, lfoPhase: 5.1),   // E4 sparkle
    ]
    static let unison: [Double] = [0.9974, 1.0, 1.0029]   // ±~0.27% detune chorus
    static let octaveAmp: Float = 0.22                     // 2nd partial → brightness, not hiss
    /// Measured via full-render simulation (chorus + reverb) → raw RMS ≈ 0.18,
    /// level-matched to the other generated soundscapes before the volume gain.
    static let masterScale: Float = 0.185
}

/// Freeverb-lite (public-domain Schroeder/Moorer design): 4 filtered-feedback combs + 2 allpasses.
/// Enough echo density per CCRMA; the right channel uses the classic +23-sample stereo spread.
final class FreeverbLite {
    private var combBufs: [[Float]]
    private var combIdx = [Int](repeating: 0, count: 4)
    private var combLP = [Float](repeating: 0, count: 4)
    private var apBufs: [[Float]]
    private var apIdx = [Int](repeating: 0, count: 2)
    private let feedback: Float = 0.86
    private let damp: Float = 0.30
    private let apGain: Float = 0.5

    init(sampleRate: Double, spread: Int) {
        let scale = sampleRate / 44_100.0
        let combs = [1116, 1188, 1277, 1356].map { Int(Double($0 + spread) * scale) }
        let aps = [556, 441].map { Int(Double($0 + spread) * scale) }
        combBufs = combs.map { [Float](repeating: 0, count: $0) }
        apBufs = aps.map { [Float](repeating: 0, count: $0) }
    }

    func process(_ input: Float) -> Float {
        var out: Float = 0
        for c in 0..<4 {
            let buf = combBufs[c][combIdx[c]]
            out += buf
            combLP[c] = buf * (1 - damp) + combLP[c] * damp
            combBufs[c][combIdx[c]] = input + combLP[c] * feedback
            combIdx[c] = (combIdx[c] + 1) % combBufs[c].count
        }
        for a in 0..<2 {
            let buf = apBufs[a][apIdx[a]]
            let y = -out + buf
            apBufs[a][apIdx[a]] = out + buf * apGain
            apIdx[a] = (apIdx[a] + 1) % apBufs[a].count
            out = y
        }
        return out
    }
}

/// Stateful per-sample pad renderer; owned by whoever runs the AVAudioSourceNode.
/// Output is already master-scaled (raw RMS ≈ 0.18) — apply only the volume gain on top.
final class PadRenderer {
    private var phases = [Double](repeating: 0, count: PadBank.notes.count * PadBank.unison.count * 2)
    private let reverbL: FreeverbLite
    private let reverbR: FreeverbLite
    private let sr: Double
    private let twoPi = 2.0 * Double.pi

    init(sampleRate: Double) {
        sr = sampleRate
        reverbL = FreeverbLite(sampleRate: sampleRate, spread: 0)
        reverbR = FreeverbLite(sampleRate: sampleRate, spread: 23)
    }

    func render(t: Double) -> (left: Float, right: Float) {
        var dryL: Float = 0
        var dryR: Float = 0
        var pi = 0
        for note in PadBank.notes {
            let breathe = Float(0.65 + 0.35 * sin(twoPi * note.lfoRate * t + note.lfoPhase))
            var voice: Float = 0
            for ratio in PadBank.unison {
                let f = note.freq * ratio
                phases[pi] += twoPi * f / sr
                if phases[pi] > twoPi { phases[pi] -= twoPi }
                voice += Float(sin(phases[pi]))
                phases[pi + 1] += twoPi * f * 2 / sr
                if phases[pi + 1] > twoPi { phases[pi + 1] -= twoPi }
                voice += Float(sin(phases[pi + 1])) * PadBank.octaveAmp
                pi += 2
            }
            voice = voice / 3 * breathe
            dryL += voice * note.ampL
            dryR += voice * note.ampR
        }
        dryL *= PadBank.masterScale
        dryR *= PadBank.masterScale
        let wetL = reverbL.process(dryL)
        let wetR = reverbR.process(dryR)
        return (dryL * 0.55 + wetL * 0.45, dryR * 0.55 + wetR * 0.45)
    }
}

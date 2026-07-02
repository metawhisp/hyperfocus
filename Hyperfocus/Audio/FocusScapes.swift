// FocusScapes.swift — the generated focus soundscapes (canon #29/#31): tonal drone/hum banks
// and the LOCK IN protocol renderer. Production source of truth — the HF_SOUND_PREVIEW gallery
// auditions these exact renderers. All banks are RMS-matched to raw ≈ 0.18 before volume gain.

import Foundation

// MARK: Drone/hum family — sine stacks with slow phase-continuous frequency drift

struct SoundPartial {
    let baseHz: Double
    let amp: Float
    let glideDepth: Double   // relative, e.g. 0.03 = ±3%
    let glideRate: Double    // Hz of the drift LFO (0.01–0.05 → 20–100 s cycles)
    let glidePhase: Double
}

enum DroneBank {
    static func partials(for mode: FocusSoundMode) -> [SoundPartial] {
        switch mode {
        case .humTide: return [
            .init(baseHz: 50, amp: 1.0, glideDepth: 0.02, glideRate: 0.020, glidePhase: 0.0),
            .init(baseHz: 100, amp: 0.6, glideDepth: 0.02, glideRate: 0.020, glidePhase: 0.0),
            .init(baseHz: 150.7, amp: 0.25, glideDepth: 0.02, glideRate: 0.020, glidePhase: 0.0),
        ]
        case .humSweep: return [
            .init(baseHz: 53, amp: 1.0, glideDepth: 0.13, glideRate: 0.012, glidePhase: 0.0),
            .init(baseHz: 106, amp: 0.5, glideDepth: 0.13, glideRate: 0.012, glidePhase: 0.0),
        ]
        case .droneChorus: return [
            .init(baseHz: 110, amp: 0.5, glideDepth: 0.012, glideRate: 0.031, glidePhase: 0.0),
            .init(baseHz: 164.8, amp: 0.35, glideDepth: 0.010, glideRate: 0.023, glidePhase: 2.1),
            .init(baseHz: 220.4, amp: 0.30, glideDepth: 0.008, glideRate: 0.017, glidePhase: 4.2),
        ]
        case .droneFifth: return [
            .init(baseHz: 110, amp: 0.6, glideDepth: 0.006, glideRate: 0.020, glidePhase: 0.0),
            .init(baseHz: 165, amp: 0.45, glideDepth: 0.018, glideRate: 0.013, glidePhase: 1.3),
        ]
        case .warmHybrid: return [
            .init(baseHz: 55, amp: 0.8, glideDepth: 0.025, glideRate: 0.016, glidePhase: 0.0),
            .init(baseHz: 110.3, amp: 0.5, glideDepth: 0.020, glideRate: 0.024, glidePhase: 1.7),
            .init(baseHz: 165.8, amp: 0.3, glideDepth: 0.015, glideRate: 0.019, glidePhase: 3.4),
        ]
        default: return []
        }
    }

    /// Master scale so each variant lands at raw RMS ≈ 0.18 before the volume gain.
    /// RMS of incoherent sines = sqrt(0.5·Σamp²); tremolo (~0.9 avg) folded in where used.
    /// Sub-heavy variants get a small perceptual boost (ear is less sensitive below ~80 Hz).
    static func masterScale(for mode: FocusSoundMode) -> Float {
        switch mode {
        case .humTide: return 0.214            // Σamp²=1.4225 → RMS .843 → ×.214 ≈ .18
        case .humSweep: return 0.262           // RMS .79 → ×.228, ×1.15 sub boost ≈ .262
        case .droneChorus: return 0.416        // RMS .481, tremolo .9 → ×.416
        case .droneFifth: return 0.377         // RMS .53, tremolo .9 → ×.377
        case .warmHybrid: return 0.283         // RMS .70 → ×.257, ×1.10 sub boost ≈ .283
        default: return 1.0
        }
    }

    static func tremolo(for mode: FocusSoundMode) -> Bool {
        mode == .droneChorus || mode == .droneFifth
    }
}

/// Stateful per-sample renderer for the drone/hum family. Output is mono (feed both channels)
/// and already master-scaled — apply only the volume gain on top.
final class DroneRenderer {
    private let partials: [SoundPartial]
    private let scale: Float
    private let hasTremolo: Bool
    private var phases: [Double]
    private let sr: Double
    private let twoPi = 2.0 * Double.pi

    init(mode: FocusSoundMode, sampleRate: Double) {
        partials = DroneBank.partials(for: mode)
        scale = DroneBank.masterScale(for: mode)
        hasTremolo = DroneBank.tremolo(for: mode)
        phases = [Double](repeating: 0, count: partials.count)
        sr = sampleRate
    }

    func render(t: Double) -> Float {
        var s: Float = 0
        for (i, p) in partials.enumerated() {
            // Phase-continuous glide: instantaneous frequency wanders slowly around base.
            let f = p.baseHz * (1 + p.glideDepth * sin(twoPi * p.glideRate * t + p.glidePhase))
            phases[i] += twoPi * f / sr
            if phases[i] > twoPi { phases[i] -= twoPi }
            s += p.amp * Float(sin(phases[i]))
        }
        if hasTremolo { s *= Float(0.9 + 0.1 * sin(twoPi * 0.15 * t)) }
        return s * scale
    }
}

// MARK: LOCK IN — reverse-engineered from FFT analysis of the reference track (canon #29):
// an A/E ambient drone with a musical 40 Hz gamma pair (A3 220 left / ~C4 260 right), interchannel
// micro-detunes (1–3 Hz shimmer), a dark low noise bed, and chord sections that change over time.
// We synthesize the recipe, not the file.

enum LockInPhase {
    case stabilize, s1, s2, s3

    /// Audition mapping: u = position within one 90 s gallery cycle.
    static func at(_ u: Double) -> LockInPhase {
        switch u {
        case ..<0.08: return .stabilize
        case ..<0.40: return .s1
        case ..<0.75: return .s2
        default: return .s3
        }
    }

    /// Production mapping: sections follow the session clock (the reference track shifts at
    /// ~1/45/95 min; compressed ~2× so a 25–45 min session hears the arc, then s3 holds).
    static func production(elapsed t: Double) -> LockInPhase {
        switch t {
        case ..<60: return .stabilize
        case ..<(20 * 60): return .s1
        case ..<(40 * 60): return .s2
        default: return .s3
        }
    }

    var name: String {
        switch self {
        case .stabilize: return "ВХОД — только подложка"
        case .s1: return "СЕКЦИЯ 1 — якорь E2/A2, шиммер 1–3 Гц"
        case .s2: return "СЕКЦИЯ 2 — гамма-пара 220L/260R"
        case .s3: return "СЕКЦИЯ 3 — удержание, на 4 дБ тише"
        }
    }

    var index: Int {   // -1 = bed only
        switch self {
        case .stabilize: return -1
        case .s1: return 0
        case .s2: return 1
        case .s3: return 2
        }
    }
}

/// Tone bank with per-section target amps (L/R separately), from the measured peak sets.
struct LockInTone {
    let freq: Double
    let ampL: [Float]   // [s1, s2, s3]
    let ampR: [Float]
}

enum LockInBank {
    // User feedback: the bed hissed ("слишком шумный"). Faithful-render simulation showed v1's
    // bed actually sat at RMS ≈ 1.10 (≈ +16 dB over the .18 row target — the noise drowned the
    // drone). v2: darker LP corners (~760/1900 Hz → ~420/900 Hz) and bedScale tuned by sim to
    // bed RMS ≈ .09, total ≈ .187 — level-matched to the other rows, hiss band −28 dB.
    static let toneScale: Float = 0.30
    static let bedScale: Float = 0.032
    static let bedLP1K: Float = 0.055
    static let bedLP2K: Float = 0.12
    static let bedGain: [Float] = [0.9, 0.9, 0.72]      // s3 ≈ −4 dB in the source

    static let tones: [LockInTone] = [
        LockInTone(freq: 82.4, ampL: [0.50, 0.50, 0.00], ampR: [0.50, 0.50, 0.00]),   // E2 anchor
        LockInTone(freq: 110.0, ampL: [0.35, 0.00, 0.00], ampR: [0.00, 0.00, 0.00]),  // A2, left voice
        LockInTone(freq: 185.7, ampL: [0.00, 0.00, 0.00], ampR: [0.30, 0.00, 0.00]),  // right voice
        LockInTone(freq: 220.0, ampL: [0.45, 0.40, 0.00], ampR: [0.00, 0.00, 0.00]),  // A3 left
        LockInTone(freq: 219.0, ampL: [0.00, 0.00, 0.00], ampR: [0.35, 0.00, 0.00]),  // 1 Hz beat vs 220L
        LockInTone(freq: 260.0, ampL: [0.00, 0.00, 0.00], ampR: [0.00, 0.40, 0.35]),  // gamma pair right
        LockInTone(freq: 138.3, ampL: [0.00, 0.40, 0.00], ampR: [0.00, 0.40, 0.00]),  // C#3, section 2
        LockInTone(freq: 207.0, ampL: [0.00, 0.35, 0.00], ampR: [0.00, 0.00, 0.00]),
        LockInTone(freq: 207.7, ampL: [0.00, 0.00, 0.00], ampR: [0.00, 0.35, 0.00]),  // 0.7 Hz detune
        LockInTone(freq: 293.7, ampL: [0.25, 0.00, 0.00], ampR: [0.25, 0.00, 0.00]),  // D4
        LockInTone(freq: 438.5, ampL: [0.12, 0.00, 0.10], ampR: [0.12, 0.00, 0.10]),  // A4 shimmer
        LockInTone(freq: 441.5, ampL: [0.12, 0.00, 0.10], ampR: [0.12, 0.00, 0.10]),  // +3 Hz beat
        LockInTone(freq: 415.3, ampL: [0.00, 0.12, 0.00], ampR: [0.00, 0.00, 0.00]),  // G#4 s2 (L)
        LockInTone(freq: 417.3, ampL: [0.00, 0.00, 0.00], ampR: [0.00, 0.12, 0.00]),  // 2 Hz beat (R)
        LockInTone(freq: 192.3, ampL: [0.00, 0.00, 0.45], ampR: [0.00, 0.00, 0.45]),  // s3 set
        LockInTone(freq: 144.9, ampL: [0.00, 0.00, 0.35], ampR: [0.00, 0.00, 0.00]),
        LockInTone(freq: 284.8, ampL: [0.00, 0.00, 0.25], ampR: [0.00, 0.00, 0.25]),
    ]
}

/// Stateful LOCK IN renderer. The schedule decides which section plays at time t —
/// 90 s audition loop in the gallery, the session clock in production.
final class LockInRenderer {
    private let schedule: (Double) -> LockInPhase
    private let sr: Double
    private let twoPi = 2.0 * Double.pi
    private var brown: Float = 0
    private var bedLP: Float = 0
    private var bedLP2: Float = 0
    private var mixBed: Float = 0
    private var tonePhases = [Double](repeating: 0, count: LockInBank.tones.count)
    private var toneGL = [Float](repeating: 0, count: LockInBank.tones.count)   // smoothed L gains
    private var toneGR = [Float](repeating: 0, count: LockInBank.tones.count)

    init(sampleRate: Double, schedule: @escaping (Double) -> LockInPhase) {
        sr = sampleRate
        self.schedule = schedule
    }

    static func auditionSchedule(_ t: Double) -> LockInPhase {
        LockInPhase.at((t.truncatingRemainder(dividingBy: 90)) / 90)
    }

    func render(t: Double) -> (left: Float, right: Float) {
        let section = schedule(t).index
        let k: Float = 0.33 / Float(sr)                      // ~3 s smoothed section crossfades

        // Bed: dark two-stage low-passed brown — presence, not hiss.
        let bedTarget: Float = section >= 0 ? LockInBank.bedGain[section] : 1.0
        mixBed += (bedTarget - mixBed) * k
        brown += (Float.random(in: -1...1) - brown * 0.02)
        bedLP += (brown * 1.3 - bedLP) * LockInBank.bedLP1K
        bedLP2 += (bedLP - bedLP2) * LockInBank.bedLP2K
        let bed = bedLP2 * LockInBank.bedScale * mixBed

        var left = bed
        var right = bed
        for (i, tone) in LockInBank.tones.enumerated() {
            let tL: Float = section >= 0 ? tone.ampL[section] : 0
            let tR: Float = section >= 0 ? tone.ampR[section] : 0
            toneGL[i] += (tL - toneGL[i]) * k
            toneGR[i] += (tR - toneGR[i]) * k
            if toneGL[i] > 0.0005 || toneGR[i] > 0.0005 {
                tonePhases[i] += twoPi * tone.freq / sr
                if tonePhases[i] > twoPi { tonePhases[i] -= twoPi }
                let s = Float(sin(tonePhases[i])) * LockInBank.toneScale
                left += s * toneGL[i]
                right += s * toneGR[i]
            }
        }
        return (left, right)
    }
}

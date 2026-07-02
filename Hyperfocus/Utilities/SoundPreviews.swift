// SoundPreviews.swift — DEBUG-only live focus-sound gallery (HF_SOUND_PREVIEW=1), round 2.
// Finalists per user: tonal DEEP HUM / WARM DRONE families. All variants: slow phase-continuous
// frequency drift (nothing static), RMS-matched levels (raw RMS target ≈ 0.18 before master gain),
// live dBFS meter so loudness equality is visible. Preview-before-prod, audio edition.

#if DEBUG
import SwiftUI
import AVFoundation

// MARK: Candidates — tonal only, each with slow frequency movement

struct SoundPartial {
    let baseHz: Double
    let amp: Float
    let glideDepth: Double   // relative, e.g. 0.03 = ±3%
    let glideRate: Double    // Hz of the drift LFO (0.01–0.05 → 20–100 s cycles)
    let glidePhase: Double
}

enum SoundCandidate: String, CaseIterable, Identifiable {
    case humTide, humSweep, droneChorus, droneFifth, warmHybrid, lockIn
    var id: String { rawValue }

    var title: String {
        switch self {
        case .humTide: return "HUM A · TIDE"
        case .humSweep: return "HUM B · DEEP SWEEP"
        case .droneChorus: return "DRONE A · CHORUS"
        case .droneFifth: return "DRONE B · FIFTH"
        case .warmHybrid: return "WARM HUM · HYBRID"
        case .lockIn: return "LOCK IN · PROTOCOL"
        }
    }

    var detail: String {
        switch self {
        case .humTide: return "50/100/150 Гц, весь стек медленно дышит ±2%"
        case .humSweep: return "фундамент плывёт 46→60 Гц за ~80 сек"
        case .droneChorus: return "аккорд A2, каждый голос расстраивается сам по себе"
        case .droneFifth: return "тоника + квинта, квинта медленно гуляет ±30 центов"
        case .warmHybrid: return "55/110/165 Гц — между хамом и дроном"
        case .lockIn: return "brown-подложка + Beta 16 Гц + Gamma 40 Гц, фазы (наушники); в превью цикл 90 сек"
        }
    }

    var partials: [SoundPartial] {
        switch self {
        case .lockIn: return []   // custom layered render, not the partial engine
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
        }
    }

    /// Master scale so each variant lands at raw RMS ≈ 0.18 before the volume gain.
    /// RMS of incoherent sines = sqrt(0.5·Σamp²); tremolo (~0.9 avg) folded in where used.
    /// Sub-heavy variants get a small perceptual boost (ear is less sensitive below ~80 Hz).
    var masterScale: Float {
        switch self {
        case .humTide: return 0.214            // Σamp²=1.4225 → RMS .843 → ×.214 ≈ .18
        case .humSweep: return 0.262           // RMS .79 → ×.228, ×1.15 sub boost ≈ .262
        case .droneChorus: return 0.416        // RMS .481, tremolo .9 → ×.416
        case .droneFifth: return 0.377         // RMS .53, tremolo .9 → ×.377
        case .warmHybrid: return 0.283         // RMS .70 → ×.257, ×1.10 sub boost ≈ .283
        case .lockIn: return 1.0               // per-layer amps already RMS-targeted ≈ .18 combined
        }
    }

    var tremolo: Bool {
        switch self {
        case .droneChorus, .droneFifth: return true
        default: return false
        }
    }
}

/// LOCK IN phase schedule (adapted from the "ADHD Lock In" protocol structure: stabilize →
/// reduce distraction → flow → sustain). `u` is normalized 0…1 over the cycle/session.
enum LockInPhase {
    case stabilize, beta, flow, sustain

    static func at(_ u: Double) -> LockInPhase {
        switch u {
        case ..<0.11: return .stabilize
        case ..<0.39: return .beta
        case ..<0.72: return .flow
        default: return .sustain
        }
    }

    var name: String {
        switch self {
        case .stabilize: return "STABILIZING — только подложка"
        case .beta: return "BETA 16 Hz — снижаем отвлечения"
        case .flow: return "BETA+GAMMA — фокус-флоу"
        case .sustain: return "GAMMA 40 Hz — удержание"
        }
    }

    /// Layer gains (bed, beta, gamma) with soft transitions handled by the caller's smoothing.
    var mix: (bed: Float, beta: Float, gamma: Float) {
        switch self {
        case .stabilize: return (1.0, 0.0, 0.0)
        case .beta: return (1.0, 1.0, 0.0)
        case .flow: return (0.9, 0.8, 1.0)
        case .sustain: return (0.9, 0.35, 1.0)
        }
    }
}

// MARK: Engine — phase-continuous glides, RMS meter, whisper ceiling

final class SoundLabEngine: ObservableObject {
    @Published var playing: SoundCandidate?
    @Published var levelDB: Double?          // live dBFS of the rendered output
    @Published var lockInPhaseName: String?  // live phase label while auditioning LOCK IN

    private let engine = AVAudioEngine()
    private var node: AVAudioSourceNode?
    private var candidate: SoundCandidate = .humTide
    private var gain: Float = 0
    var targetGain: Float = 0.10

    private var phases = [Double](repeating: 0, count: 8)
    private var sampleIndex: Double = 0
    private var rmsAccum: Double = 0
    private var rmsCount: Int = 0
    // lock-in state
    private var brown: Float = 0
    private var bedLP: Float = 0
    private var mixBed: Float = 0, mixBeta: Float = 0, mixGamma: Float = 0   // smoothed layer gains

    func play(_ c: SoundCandidate, volume: Float) {
        targetGain = volume
        candidate = c
        gain = 0
        phases = [Double](repeating: 0, count: 8)
        sampleIndex = 0; rmsAccum = 0; rmsCount = 0
        if node == nil { buildNode() }
        if !engine.isRunning { try? engine.start() }
        playing = c
    }

    func stop() {
        engine.pause()
        playing = nil
        levelDB = nil
    }

    private func buildNode() {
        let format = engine.outputNode.inputFormat(forBus: 0)
        let sr = format.sampleRate > 0 ? format.sampleRate : 44_100
        let fadeStep = Float(1.0 / (2.0 * sr))
        let twoPi = 2.0 * Double.pi
        let meterWindow = Int(sr / 4)        // publish level 4×/s

        let src = AVAudioSourceNode { [weak self] _, _, frameCount, abl -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let partials = self.candidate.partials
            let scale = self.candidate.masterScale
            let hasTremolo = self.candidate.tremolo

            let isLockIn = self.candidate == .lockIn
            for frame in 0..<Int(frameCount) {
                if self.gain < self.targetGain { self.gain = min(self.targetGain, self.gain + fadeStep) }
                if self.gain > self.targetGain { self.gain = max(self.targetGain, self.gain - fadeStep) }
                self.sampleIndex += 1
                let t = self.sampleIndex / sr

                var left: Float = 0
                var right: Float = 0

                if isLockIn {
                    // 90 s audition cycle through the protocol phases; layer gains smoothed (~1 s).
                    let u = (t.truncatingRemainder(dividingBy: 90)) / 90
                    let target = LockInPhase.at(u).mix
                    let k: Float = 1.0 / Float(sr)
                    self.mixBed += (target.bed - self.mixBed) * k
                    self.mixBeta += (target.beta - self.mixBeta) * k
                    self.mixGamma += (target.gamma - self.mixGamma) * k

                    // Bed: dark low-passed brown, shared by both ears.
                    self.brown += (Float.random(in: -1...1) - self.brown * 0.02)
                    self.bedLP += (self.brown * 1.3 - self.bedLP) * 0.06
                    let bed = self.bedLP * 0.33 * self.mixBed        // ≈ RMS .10 contribution

                    // Beta 16 Hz pair: 100 L / 116 R. Gamma 40 Hz pair: 220 L / 260 R.
                    self.phases[0] += twoPi * 100 / sr
                    self.phases[1] += twoPi * 116 / sr
                    self.phases[2] += twoPi * 220 / sr
                    self.phases[3] += twoPi * 260 / sr
                    for i in 0..<4 where self.phases[i] > twoPi { self.phases[i] -= twoPi }

                    left = bed + Float(sin(self.phases[0])) * 0.16 * self.mixBeta
                        + Float(sin(self.phases[2])) * 0.13 * self.mixGamma
                    right = bed + Float(sin(self.phases[1])) * 0.16 * self.mixBeta
                        + Float(sin(self.phases[3])) * 0.13 * self.mixGamma
                } else {
                    var s: Float = 0
                    for (i, p) in partials.enumerated() {
                        // Phase-continuous glide: instantaneous frequency wanders slowly around base.
                        let f = p.baseHz * (1 + p.glideDepth * sin(twoPi * p.glideRate * t + p.glidePhase))
                        self.phases[i] += twoPi * f / sr
                        if self.phases[i] > twoPi { self.phases[i] -= twoPi }
                        s += p.amp * Float(sin(self.phases[i]))
                    }
                    if hasTremolo { s *= Float(0.9 + 0.1 * sin(twoPi * 0.15 * t)) }
                    s *= scale
                    left = s; right = s
                }

                let outL = max(-1, min(1, left * self.gain))
                let outR = max(-1, min(1, right * self.gain))
                for (ch, buf) in buffers.enumerated() {
                    buf.mData!.assumingMemoryBound(to: Float.self)[frame] = ch == 0 ? outL : outR
                }

                self.rmsAccum += Double(outL * outL + outR * outR) / 2
                self.rmsCount += 1
                if self.rmsCount >= meterWindow {
                    let rms = (self.rmsAccum / Double(self.rmsCount)).squareRoot()
                    let db = rms > 0 ? 20 * log10(rms) : -120
                    let phaseName: String? = isLockIn
                        ? LockInPhase.at((t.truncatingRemainder(dividingBy: 90)) / 90).name : nil
                    self.rmsAccum = 0; self.rmsCount = 0
                    DispatchQueue.main.async {
                        self.levelDB = db
                        self.lockInPhaseName = phaseName
                    }
                }
            }
            return noErr
        }
        engine.attach(src)
        engine.connect(src, to: engine.mainMixerNode, format: format)
        node = src
    }
}

// MARK: Gallery UI

struct SoundGalleryView: View {
    @StateObject private var lab = SoundLabEngine()
    @State private var volume: Double = 0.4   // ×0.25 ceiling → whisper

    var body: some View {
        VStack(spacing: 14) {
            Text("ЗВУКИ ФОКУСА v2 — хам и дрон, частоты плывут, уровни выровнены")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 8) {
                ForEach(SoundCandidate.allCases) { c in
                    row(c)
                }
            }

            HStack(spacing: 10) {
                Text("ГРОМКОСТЬ").font(.system(size: 9, weight: .bold)).tracking(1.2)
                    .foregroundStyle(FD.label)
                Slider(value: $volume, in: 0.05...1)
                    .frame(width: 190)
                    .tint(FD.lime)
                    .onChange(of: volume) { _, v in lab.targetGain = Float(v) * 0.25 }
                Text("\(Int(volume * 100))%").font(FD.matrix(11)).foregroundStyle(FD.lime)
                Spacer()
                Text(lab.levelDB.map { String(format: "%.0f dBFS", $0) } ?? "— dBFS")
                    .font(FD.matrix(11))
                    .foregroundStyle(lab.levelDB == nil ? FD.label : FD.amber)
            }
        }
        .padding(24)
        .frame(width: 540)
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
                Circle().fill(FD.lime.opacity(0.12)).frame(width: 180, height: 180)
                    .blur(radius: 70).offset(x: -50, y: -60)
            }
        )
        .preferredColorScheme(.dark)
    }

    private func row(_ c: SoundCandidate) -> some View {
        let active = lab.playing == c
        return FDInset {
            HStack(spacing: 12) {
                Button {
                    if active { lab.stop() } else { lab.play(c, volume: Float(volume) * 0.25) }
                } label: {
                    Image(systemName: active ? "stop.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(active ? .black : FD.lime)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(active ?
                            AnyShapeStyle(FD.limeGradient) : AnyShapeStyle(Color.black.opacity(0.35))))
                        .shadow(color: active ? FD.lime.opacity(0.7) : .clear, radius: 8)
                }
                .buttonStyle(HFPressStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(c.title).font(FD.matrix(13))
                        .foregroundStyle(active ? FD.lime : .white)
                    if active, c == .lockIn, let phase = lab.lockInPhaseName {
                        Text(phase).font(.system(size: 11, weight: .semibold)).foregroundStyle(FD.amber)
                    } else {
                        Text(c.detail).font(.system(size: 11)).foregroundStyle(FD.label)
                    }
                }
                Spacer()
            }
            .frame(width: 460)
        }
    }
}

@MainActor
enum SoundPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 540, height: 480),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Focus Sound Gallery v2"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: SoundGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

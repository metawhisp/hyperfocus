// SoundPreviews.swift — DEBUG-only live focus-sound gallery (HF_SOUND_PREVIEW=1), round 3.
// All candidates are production FocusSoundModes now — the gallery auditions the exact renderers
// the app ships (PadSynth.swift + FocusScapes.swift), with a live dBFS meter so loudness
// equality stays visible. Preview-before-prod, audio edition.

#if DEBUG
import SwiftUI
import AVFoundation

// MARK: Candidates — gallery labels over the shipped generated modes

enum SoundCandidate: String, CaseIterable, Identifiable {
    case pad, humTide, humSweep, droneChorus, droneFifth, warmHybrid, lockIn
    var id: String { rawValue }

    /// The production mode this row auditions (same raw values by construction).
    var mode: FocusSoundMode { FocusSoundMode(rawValue: rawValue)! }

    var title: String {
        switch self {
        case .pad: return "PAD · AMBIENT"
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
        case .pad: return "настоящий пад: аккорд A/E, unison-детюн, дышащие голоса, реверб; без шума"
        case .humTide: return "50/100/150 Гц, весь стек медленно дышит ±2%"
        case .humSweep: return "фундамент плывёт 46→60 Гц за ~80 сек"
        case .droneChorus: return "аккорд A2, каждый голос расстраивается сам по себе"
        case .droneFifth: return "тоника + квинта, квинта медленно гуляет ±30 центов"
        case .warmHybrid: return "55/110/165 Гц — между хамом и дроном"
        case .lockIn: return "дрон A/E + гамма-пара 220L/260R; подложка тише и темнее (v2); цикл 90 сек"
        }
    }
}

// MARK: Engine — thin shell over the production renderers + RMS meter

final class SoundLabEngine: ObservableObject {
    @Published var playing: SoundCandidate?
    @Published var levelDB: Double?          // live dBFS of the rendered output
    @Published var lockInPhaseName: String?  // live phase label while auditioning LOCK IN

    private let engine = AVAudioEngine()
    private var node: AVAudioSourceNode?
    private var candidate: SoundCandidate = .humTide
    private var gain: Float = 0
    var targetGain: Float = 0.10

    private var sampleIndex: Double = 0
    private var rmsAccum: Double = 0
    private var rmsCount: Int = 0
    // Shared production renderers (PadSynth.swift / FocusScapes.swift) — gallery == shipped sound.
    private var pad: PadRenderer?
    private var drone: DroneRenderer?
    private var lockIn: LockInRenderer?

    func play(_ c: SoundCandidate, volume: Float) {
        targetGain = volume
        candidate = c
        gain = 0
        sampleIndex = 0; rmsAccum = 0; rmsCount = 0
        // Allocate renderers off the render thread; the gallery loops LOCK IN's 90 s audition cycle.
        let rate = engine.outputNode.inputFormat(forBus: 0).sampleRate
        let sr = rate > 0 ? rate : 44_100
        switch c {
        case .pad:
            if pad == nil { pad = PadRenderer(sampleRate: sr) }
        case .lockIn:
            if lockIn == nil { lockIn = LockInRenderer(sampleRate: sr,
                                                       schedule: LockInRenderer.auditionSchedule) }
        default:
            drone = DroneRenderer(mode: c.mode, sampleRate: sr)
        }
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
        let meterWindow = Int(sr / 4)        // publish level 4×/s

        let src = AVAudioSourceNode { [weak self] _, _, frameCount, abl -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let current = self.candidate
            for frame in 0..<Int(frameCount) {
                if self.gain < self.targetGain { self.gain = min(self.targetGain, self.gain + fadeStep) }
                if self.gain > self.targetGain { self.gain = max(self.targetGain, self.gain - fadeStep) }
                self.sampleIndex += 1
                let t = self.sampleIndex / sr

                var left: Float = 0
                var right: Float = 0
                switch current {
                case .pad:
                    if let out = self.pad?.render(t: t) { left = out.left; right = out.right }
                case .lockIn:
                    if let out = self.lockIn?.render(t: t) { left = out.left; right = out.right }
                default:
                    if let s = self.drone?.render(t: t) { left = s; right = s }
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
                    let phaseName: String? = current == .lockIn
                        ? LockInRenderer.auditionSchedule(t).name : nil
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
            Text("ЗВУКИ ФОКУСА v3 — все варианты доступны в Settings, уровни выровнены")
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
        w.title = "Hyperfocus — Focus Sound Gallery v3"
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

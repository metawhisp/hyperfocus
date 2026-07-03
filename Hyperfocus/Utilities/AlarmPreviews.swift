// AlarmPreviews.swift — DEBUG-only live gallery (HF_ALARM_PREVIEW=1): away-alarm sound candidates.
// The current alarm is a harsh brown-noise blast ("жёсткий, но нормальный") — the user wants a
// choice: siren, ticking, etc. All procedural (no assets), auditioned at the real alarm volume
// path. The pick becomes a Settings "Alarm sound" option. Preview-before-prod.

#if DEBUG
import SwiftUI
import AVFoundation

enum AlarmCandidate: String, CaseIterable, Identifiable {
    case noise, siren, tick, sonar, beeps, heartbeat
    var id: String { rawValue }

    var title: String {
        switch self {
        case .noise:     return "A · DEEP NOISE (сейчас)"
        case .siren:     return "B · SIREN"
        case .tick:      return "C · TICK-TOCK"
        case .sonar:     return "D · SONAR"
        case .beeps:     return "E · TRIPLE BEEP"
        case .heartbeat: return "F · HEARTBEAT"
        }
    }
    var detail: String {
        switch self {
        case .noise:     return "текущий шумовой напор — точка отсчёта"
        case .siren:     return "плавная двутональная сирена 500↔750 Гц"
        case .tick:      return "тревожный метроном — тик каждые полсекунды"
        case .sonar:     return "пинг подлодки с длинным хвостом, раз в 1.6 с"
        case .beeps:     return "классические три бипа 880 Гц с паузой"
        case .heartbeat: return "низкий двойной удар сердца, раз в секунду"
        }
    }
}

final class AlarmLabEngine: ObservableObject {
    @Published var playing: AlarmCandidate?
    private let engine = AVAudioEngine()
    private var node: AVAudioSourceNode?
    private var candidate: AlarmCandidate = .noise
    var targetGain: Float = 0.5
    private var gain: Float = 0
    private var brown: Float = 0
    private var phase: Double = 0
    private var sampleIndex: Double = 0

    func play(_ c: AlarmCandidate, volume: Float) {
        candidate = c
        targetGain = volume
        gain = 0; brown = 0; phase = 0; sampleIndex = 0
        if node == nil { buildNode() }
        if !engine.isRunning { try? engine.start() }
        playing = c
    }

    func stop() {
        engine.pause()
        playing = nil
    }

    private func buildNode() {
        let format = engine.outputNode.inputFormat(forBus: 0)
        let sr = format.sampleRate > 0 ? format.sampleRate : 44_100
        let twoPi = 2.0 * Double.pi
        let fadeStep = Float(1.0 / (0.8 * sr))                    // alarm's 0.8 s fade-in

        let src = AVAudioSourceNode { [weak self] _, _, frameCount, abl -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let c = self.candidate
            for frame in 0..<Int(frameCount) {
                if self.gain < self.targetGain { self.gain = min(self.targetGain, self.gain + fadeStep) }
                if self.gain > self.targetGain { self.gain = max(self.targetGain, self.gain - fadeStep) }
                self.sampleIndex += 1
                let t = self.sampleIndex / sr
                var s: Float = 0

                switch c {
                case .noise:
                    // Same recipe as production AlarmService: integrated brown noise, hot gain.
                    self.brown += (Float.random(in: -1...1) - self.brown * 0.02)
                    s = self.brown * 0.35
                case .siren:
                    let f = 500 + 250 * (0.5 + 0.5 * sin(twoPi * 0.9 * t))
                    self.phase += twoPi * f / sr
                    if self.phase > twoPi { self.phase -= twoPi }
                    s = Float(sin(self.phase)) * 0.5
                case .tick:
                    let u = t.truncatingRemainder(dividingBy: 0.5)
                    if u < 0.035 {
                        let env = Float(exp(-u * 160))
                        s = (Float.random(in: -1...1) * 0.25 + Float(sin(twoPi * 1800 * u)) * 0.75) * env * 0.8
                    }
                case .sonar:
                    let u = t.truncatingRemainder(dividingBy: 1.6)
                    let ping = Float(sin(twoPi * 880 * u)) * Float(exp(-u * 5)) * 0.6
                    let echoU = u - 0.28
                    let echo = echoU > 0 ? Float(sin(twoPi * 880 * echoU)) * Float(exp(-echoU * 5)) * 0.22 : 0
                    s = ping + echo
                case .beeps:
                    let u = t.truncatingRemainder(dividingBy: 1.2)
                    for k in 0..<3 {
                        let b = u - Double(k) * 0.2
                        if b > 0 && b < 0.12 {
                            let env = Float(min(1, b / 0.008)) * Float(min(1, (0.12 - b) / 0.02))
                            s += Float(sin(twoPi * 880 * b)) * env * 0.5
                        }
                    }
                case .heartbeat:
                    let u = t.truncatingRemainder(dividingBy: 1.0)
                    for (off, amp) in [(0.0, 0.9), (0.18, 0.6)] {
                        let b = u - off
                        if b > 0 && b < 0.14 {
                            s += Float(sin(twoPi * 55 * b)) * Float(exp(-b * 28)) * Float(amp)
                        }
                    }
                }

                let out = max(-1, min(1, s * self.gain))
                for (ch, buf) in buffers.enumerated() {
                    _ = ch
                    buf.mData!.assumingMemoryBound(to: Float.self)[frame] = out
                }
            }
            return noErr
        }
        engine.attach(src)
        engine.connect(src, to: engine.mainMixerNode, format: format)
        node = src
    }
}

struct AlarmGalleryView: View {
    @StateObject private var lab = AlarmLabEngine()
    @State private var volume: Double = 0.5

    var body: some View {
        VStack(spacing: 14) {
            Text("ЗВУК ТРЕВОГИ (away) — 6 кандидатов, выбранный станет опцией в Settings")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 8) {
                ForEach(AlarmCandidate.allCases) { c in row(c) }
            }

            HStack(spacing: 10) {
                Text("ГРОМКОСТЬ").font(.system(size: 9, weight: .bold)).tracking(1.2)
                    .foregroundStyle(FD.label)
                Slider(value: $volume, in: 0.1...1)
                    .frame(width: 190).tint(FD.lime)
                    .onChange(of: volume) { _, v in lab.targetGain = Float(v) }
                Text("\(Int(volume * 100))%").font(FD.matrix(11)).foregroundStyle(FD.lime)
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 540)
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
                Circle().fill(FD.redLED.opacity(0.12)).frame(width: 180, height: 180)
                    .blur(radius: 70).offset(x: -50, y: -60)
            }
        )
        .preferredColorScheme(.dark)
    }

    private func row(_ c: AlarmCandidate) -> some View {
        let active = lab.playing == c
        return FDInset {
            HStack(spacing: 12) {
                Button {
                    if active { lab.stop() } else { lab.play(c, volume: Float(volume)) }
                } label: {
                    Image(systemName: active ? "stop.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(active ? .black : FD.redLED)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(active ?
                            AnyShapeStyle(FD.limeGradient) : AnyShapeStyle(Color.black.opacity(0.35))))
                        .shadow(color: active ? FD.lime.opacity(0.7) : .clear, radius: 8)
                }
                .buttonStyle(HFPressStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(c.title).font(FD.matrix(13))
                        .foregroundStyle(active ? FD.lime : .white)
                    Text(c.detail).font(.system(size: 11)).foregroundStyle(FD.label)
                }
                Spacer()
            }
            .frame(width: 460)
        }
    }
}

@MainActor
enum AlarmPreviewWindow {
    private static var window: NSWindow?
    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 540, height: 520),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Alarm Sound Gallery"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: AlarmGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

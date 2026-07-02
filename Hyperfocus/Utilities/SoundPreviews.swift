// SoundPreviews.swift — DEBUG-only live focus-sound gallery (HF_SOUND_PREVIEW=1): seven procedural
// soundscape candidates the user can audition and pick from. Preview-before-prod, audio edition.
// Everything is whisper-quiet by construction; the shared slider tunes the audition level.

#if DEBUG
import SwiftUI
import AVFoundation

// MARK: Candidates

enum SoundCandidate: String, CaseIterable, Identifiable {
    case ocean, air, wind, rain, hum, drone, binaural
    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean: return "OCEAN"
        case .air: return "AIR"
        case .wind: return "WIND"
        case .rain: return "RAIN"
        case .hum: return "DEEP HUM"
        case .drone: return "WARM DRONE"
        case .binaural: return "FOCUS BEATS 40 HZ"
        }
    }

    var detail: String {
        switch self {
        case .ocean: return "тёмный шум с медленными «волнами»"
        case .air: return "почти неслышный низкий гул кондиционера"
        case .wind: return "мягкий ветер, тембр медленно гуляет"
        case .rain: return "приглушённый дождь за окном"
        case .hum: return "низкие частоты 50/100 Гц — трансформаторный фон"
        case .drone: return "тихий музыкальный аккорд-подушка (A2+E3+A3)"
        case .binaural: return "200/240 Гц по ушам → биение 40 Гц (наушники)"
        }
    }
}

// MARK: Engine — one source node, switchable algorithm, hard whisper ceiling

final class SoundLabEngine: ObservableObject {
    @Published var playing: SoundCandidate?

    private let engine = AVAudioEngine()
    private var node: AVAudioSourceNode?
    private var candidate: SoundCandidate = .ocean
    private var gain: Float = 0
    var targetGain: Float = 0.10          // slider-controlled; ceiling applied by caller

    // DSP state
    private var brownL: Float = 0, brownR: Float = 0
    private var lp1: Float = 0, lp2: Float = 0, lpR1: Float = 0, lpR2: Float = 0
    private var sampleIndex: Double = 0
    private var windDrift: Float = 0

    func play(_ c: SoundCandidate, volume: Float) {
        targetGain = volume
        candidate = c
        resetState()
        if node == nil { buildNode() }
        if !engine.isRunning { try? engine.start() }
        playing = c
    }

    func stop() {
        engine.pause()
        playing = nil
    }

    private func resetState() {
        gain = 0
        brownL = 0; brownR = 0; lp1 = 0; lp2 = 0; lpR1 = 0; lpR2 = 0
        sampleIndex = 0; windDrift = 0
    }

    private func buildNode() {
        let format = engine.outputNode.inputFormat(forBus: 0)
        let sr = format.sampleRate > 0 ? format.sampleRate : 44_100
        let fadeStep = Float(1.0 / (2.0 * sr))
        let twoPi = 2.0 * Double.pi

        let src = AVAudioSourceNode { [weak self] _, _, frameCount, abl -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            for frame in 0..<Int(frameCount) {
                if self.gain < self.targetGain { self.gain = min(self.targetGain, self.gain + fadeStep) }
                if self.gain > self.targetGain { self.gain = max(self.targetGain, self.gain - fadeStep) }
                self.sampleIndex += 1
                let t = self.sampleIndex / sr
                var left: Float = 0, right: Float = 0

                switch self.candidate {
                case .ocean:
                    self.brownL += (Float.random(in: -1...1) - self.brownL * 0.02)
                    self.brownR += (Float.random(in: -1...1) - self.brownR * 0.02)
                    self.lp1 += (self.brownL * 1.2 - self.lp1) * 0.03
                    self.lpR1 += (self.brownR * 1.2 - self.lpR1) * 0.03
                    let swell = Float(0.55 + 0.45 * sin(twoPi * 0.07 * t))
                    left = self.lp1 * swell; right = self.lpR1 * swell

                case .air:
                    self.brownL += (Float.random(in: -1...1) - self.brownL * 0.02)
                    self.lp1 += (self.brownL - self.lp1) * 0.02
                    self.lp2 += (self.lp1 - self.lp2) * 0.02
                    left = self.lp2 * 1.6; right = self.lp2 * 1.6

                case .wind:
                    self.windDrift += Float.random(in: -0.00002...0.00002)
                    self.windDrift = max(-0.02, min(0.02, self.windDrift))
                    let k = 0.03 + 0.03 * Float(0.5 + 0.5 * sin(twoPi * 0.05 * t)) + self.windDrift
                    self.lp1 += (Float.random(in: -1...1) * 1.3 - self.lp1) * max(0.005, k)
                    self.lp2 += (self.lp1 - self.lp2) * 0.08
                    left = self.lp2 * 1.4; right = self.lp2 * 1.4

                case .rain:
                    self.lp1 += (Float.random(in: -1...1) - self.lp1) * 0.10
                    self.lpR1 += (Float.random(in: -1...1) - self.lpR1) * 0.10
                    self.lp2 += (self.lp1 - self.lp2) * 0.35
                    self.lpR2 += (self.lpR1 - self.lpR2) * 0.35
                    left = self.lp2 * 0.9; right = self.lpR2 * 0.9

                case .hum:
                    let s = Float(sin(twoPi * 50 * t)) + 0.6 * Float(sin(twoPi * 100 * t))
                        + 0.25 * Float(sin(twoPi * 151 * t))
                    left = s * 0.35; right = s * 0.35

                case .drone:
                    let trem = Float(0.9 + 0.1 * sin(twoPi * 0.15 * t))
                    let s = 0.5 * Float(sin(twoPi * 110 * t)) + 0.35 * Float(sin(twoPi * 164.8 * t))
                        + 0.3 * Float(sin(twoPi * 220.5 * t))
                    left = s * 0.4 * trem; right = s * 0.4 * trem

                case .binaural:
                    self.brownL += (Float.random(in: -1...1) - self.brownL * 0.02)
                    self.lp1 += (self.brownL - self.lp1) * 0.06
                    left = Float(sin(twoPi * 200 * t)) * 0.22 + self.lp1 * 0.10
                    right = Float(sin(twoPi * 240 * t)) * 0.22 + self.lp1 * 0.10
                }

                left = max(-1, min(1, left * self.gain))
                right = max(-1, min(1, right * self.gain))
                for (ch, buf) in buffers.enumerated() {
                    buf.mData!.assumingMemoryBound(to: Float.self)[frame] = ch == 0 ? left : right
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
            Text("ЗВУКИ ФОКУСА — нажми PLAY, слушай, назови выбор")
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
                    .frame(width: 220)
                    .tint(FD.lime)
                    .onChange(of: volume) { _, v in lab.targetGain = Float(v) * 0.25 }
                Text("\(Int(volume * 100))%").font(FD.matrix(11)).foregroundStyle(FD.lime)
            }
        }
        .padding(24)
        .frame(width: 520)
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
                    Text(c.detail).font(.system(size: 11)).foregroundStyle(FD.label)
                }
                Spacer()
            }
            .frame(width: 440)
        }
    }
}

@MainActor
enum SoundPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 520, height: 560),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Focus Sound Gallery"
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

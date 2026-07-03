// AlarmService.swift — procedural away-alarm implementation of AlarmPlaying (canon §6, #40).
//
// Four generated sounds (no audio assets), user-picked in Settings: the original brown-noise
// hum, a two-tone siren, a triple beep and a massive heartbeat. Fades in over 0.8 s and loops
// until stop().

import AVFoundation

enum AlarmSound: String, Codable, CaseIterable {
    case noise, siren, beeps, heartbeat
    var displayName: String {
        switch self {
        case .noise: return "Deep Noise"
        case .siren: return "Siren"
        case .beeps: return "Triple Beep"
        case .heartbeat: return "Heartbeat"
        }
    }
}

final class AlarmService: AlarmPlaying {
    private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var brown: Float = 0
    private var phase: Double = 0
    private var sampleIndex: Double = 0
    private var targetVolume: Float = 0.5
    private var currentGain: Float = 0          // ramped toward targetVolume for the fade-in
    private var sound: AlarmSound = .noise

    func start(volume: Float) { start(volume: volume, sound: .noise) }

    func start(volume: Float, sound: AlarmSound) {
        guard !isPlaying else { targetVolume = volume; self.sound = sound; return }
        targetVolume = volume
        self.sound = sound
        currentGain = 0
        brown = 0; phase = 0; sampleIndex = 0

        let format = engine.outputNode.inputFormat(forBus: 0)
        let sr = format.sampleRate > 0 ? format.sampleRate : 44_100
        let gainStep = Float(1.0 / max(1, Constants.Alarm.fadeInSeconds * sr))
        let twoPi = 2.0 * Double.pi

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                self.sampleIndex += 1
                let t = self.sampleIndex / sr
                var sample: Float = 0

                switch self.sound {
                case .noise:
                    // Brown noise: integrate white noise with a small leak (canon §6 formula).
                    let white = Float.random(in: -1...1)
                    self.brown += (white - self.brown * Constants.Alarm.brownNoiseIntegration)
                    sample = self.brown * Constants.Alarm.brownNoiseGain
                case .siren:
                    let f = 500 + 250 * (0.5 + 0.5 * sin(twoPi * 0.9 * t))
                    self.phase += twoPi * f / sr
                    if self.phase > twoPi { self.phase -= twoPi }
                    sample = Float(sin(self.phase)) * 0.55
                case .beeps:
                    let u = t.truncatingRemainder(dividingBy: 1.2)
                    for k in 0..<3 {
                        let b = u - Double(k) * 0.2
                        if b > 0 && b < 0.12 {
                            let env = Float(min(1, b / 0.008)) * Float(min(1, (0.12 - b) / 0.02))
                            sample += Float(sin(twoPi * 880 * b)) * env * 0.55
                        }
                    }
                case .heartbeat:
                    // Massive double thump (user: "громче и массивнее"): 55 Hz fundamental +
                    // 82 Hz body + a click of presence, long decay, soft-clipped for weight.
                    let u = t.truncatingRemainder(dividingBy: 1.0)
                    for (off, amp) in [(0.0, 1.8), (0.18, 1.2)] {
                        let b = u - off
                        if b > 0 && b < 0.30 {
                            let body = sin(twoPi * 55 * b) + 0.6 * sin(twoPi * 82 * b)
                            let click = 0.25 * sin(twoPi * 320 * b) * exp(-b * 60)
                            sample += Float((body * exp(-b * 14) + click) * amp)
                        }
                    }
                    sample = tanh(sample * 1.4)          // saturation = mass
                }

                if self.currentGain < self.targetVolume {
                    self.currentGain = min(self.targetVolume, self.currentGain + gainStep)
                }
                sample *= self.currentGain
                sample = max(-1, min(1, sample))
                for buffer in abl {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node

        do {
            try engine.start()
            isPlaying = true
        } catch {
            NSLog("Hyperfocus: alarm engine failed to start: \(error.localizedDescription)")
            cleanup()
        }
    }

    func stop() {
        guard isPlaying else { return }
        engine.stop()
        cleanup()
    }

    private func cleanup() {
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        isPlaying = false
    }
}

// FocusSoundService.swift — procedural focus soundscape for hyperfocus sessions (canon #29).
// Two generated modes, no audio assets:
//   • brown    — deep brown-noise bed (speaker-safe)
//   • binaural — 200 Hz left / 240 Hz right sine pair → perceived 40 Hz beat (headphones)
// Starts with the session, ducks while away (the alarm owns that moment), stops at the end.
// No efficacy claims are made in UI copy — these are "focus frequencies", not medicine.

import AVFoundation

enum FocusSoundMode: String, Codable, CaseIterable {
    case brown, binaural, custom
    var displayName: String {
        switch self {
        case .brown: return "Deep Noise"
        case .binaural: return "Focus Beats 40 Hz"
        case .custom: return "Custom Audio"
        }
    }
}

final class FocusSoundService {
    private(set) var isPlaying = false

    /// Directory for user-picked custom audio (inside the sandbox container — always readable).
    static func customSoundDirectory() -> URL {
        SessionStore.defaultDirectoryURL().appendingPathComponent("FocusSound", isDirectory: true)
    }

    private var player: AVAudioPlayer?
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var brownL: Float = 0
    private var brownR: Float = 0
    private var lpL: Float = 0        // one-pole low-pass state — darkens the noise into a soft rumble
    private var lpR: Float = 0
    private var phaseL: Double = 0
    private var phaseR: Double = 0
    private var gain: Float = 0
    private var targetGain: Float = 0.1
    private var mode: FocusSoundMode = .brown

    /// Background sound must stay a whisper — hard ceiling on the effective gain regardless of slider.
    private let maxGain: Float = 0.22

    func start(mode: FocusSoundMode, volume: Float, customFileURL: URL? = nil) {
        if mode == .custom {
            startCustom(volume: volume, url: customFileURL)
            return
        }
        let clamped = min(volume, 1) * maxGain                   // slider 0…1 → whisper range
        guard !isPlaying else {
            self.mode = mode
            targetGain = clamped
            return
        }
        self.mode = mode
        targetGain = clamped
        gain = 0
        brownL = 0; brownR = 0; lpL = 0; lpR = 0; phaseL = 0; phaseR = 0

        let format = engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44_100
        let gainStep = Float(1.0 / (4.0 * sampleRate))          // 4 s creep-in — appearance unnoticeable
        let leftHz = 200.0, rightHz = 240.0                     // Δ40 Hz gamma-band beat
        let twoPi = 2.0 * Double.pi
        let lpK: Float = 0.06                                    // ~550 Hz cutoff → dark, no hiss

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                if self.gain < self.targetGain { self.gain = min(self.targetGain, self.gain + gainStep) }
                if self.gain > self.targetGain { self.gain = max(self.targetGain, self.gain - gainStep) }

                var left: Float = 0
                var right: Float = 0
                switch self.mode {
                case .brown:
                    // Independent brown noise per channel, then low-passed into a dark rumble —
                    // a barely-there presence, not hiss.
                    self.brownL += (Float.random(in: -1...1) - self.brownL * 0.02)
                    self.brownR += (Float.random(in: -1...1) - self.brownR * 0.02)
                    self.lpL += (self.brownL * 1.3 - self.lpL) * lpK
                    self.lpR += (self.brownR * 1.3 - self.lpR) * lpK
                    left = self.lpL
                    right = self.lpR
                case .custom:
                    break   // custom mode never reaches the synth path (AVAudioPlayer handles it)
                case .binaural:
                    // Quiet sine pair; a whisper of low-passed brown keeps it from feeling sterile.
                    self.phaseL += twoPi * leftHz / sampleRate
                    self.phaseR += twoPi * rightHz / sampleRate
                    if self.phaseL > twoPi { self.phaseL -= twoPi }
                    if self.phaseR > twoPi { self.phaseR -= twoPi }
                    self.brownL += (Float.random(in: -1...1) - self.brownL * 0.02)
                    self.lpL += (self.brownL - self.lpL) * lpK
                    left = Float(sin(self.phaseL)) * 0.22 + self.lpL * 0.10
                    right = Float(sin(self.phaseR)) * 0.22 + self.lpL * 0.10
                }
                left = max(-1, min(1, left * self.gain))
                right = max(-1, min(1, right * self.gain))

                for (channel, buffer) in abl.enumerated() {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = channel == 0 ? left : right
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
            NSLog("Hyperfocus: focus sound engine failed to start: \(error.localizedDescription)")
            cleanup()
        }
    }

    /// User-picked audio: loops for the whole session, gentle 3 s fade-in, music-level ceiling.
    private func startCustom(volume: Float, url: URL?) {
        guard !isPlaying else {
            player?.setVolume(min(volume, 1) * 0.6, fadeDuration: 0.5)
            return
        }
        guard let url, let p = try? AVAudioPlayer(contentsOf: url) else {
            NSLog("Hyperfocus: custom focus audio missing/unreadable — staying silent")
            return
        }
        p.numberOfLoops = -1
        p.volume = 0
        p.prepareToPlay()
        p.play()
        p.setVolume(min(volume, 1) * 0.6, fadeDuration: 3.0)
        player = p
        isPlaying = true
    }

    func stop() {
        guard isPlaying else { return }
        if let p = player {
            p.setVolume(0, fadeDuration: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                p.stop()
                if self?.player === p { self?.player = nil }
            }
            isPlaying = false
            return
        }
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

// FocusSoundService.swift — procedural focus soundscape for hyperfocus sessions (canon #29/#31).
// Generated modes, no audio assets — the user picks the starting sound in Settings and can
// switch anytime:
//   • pad         — our own ambient pad (PadSynth.swift): tonal A/E chord, no noise — the default
//   • hum/drone   — tonal sine stacks with slow frequency drift (FocusScapes.swift)
//   • lockIn      — the LOCK IN protocol: sectioned A/E drone following the session clock
//   • brown       — deep brown-noise bed (speaker-safe)
//   • binaural    — 200 Hz left / 240 Hz right sine pair → perceived 40 Hz beat (headphones)
// Starts with the session and swells in over ~12 s on a perceptual (squared) curve — the music
// must appear gradually, never as a jump cut. Ducks while away (the alarm owns that moment).
// No efficacy claims are made in UI copy — these are "focus frequencies", not medicine.

import AVFoundation

enum FocusSoundMode: String, Codable, CaseIterable {
    case pad, humTide, humSweep, droneChorus, droneFifth, warmHybrid, lockIn
    case brown, binaural, custom

    var displayName: String {
        switch self {
        case .pad: return "Ambient Pad"
        case .humTide: return "Deep Hum · Tide"
        case .humSweep: return "Deep Hum · Sweep"
        case .droneChorus: return "Warm Drone · Chorus"
        case .droneFifth: return "Warm Drone · Fifth"
        case .warmHybrid: return "Warm Hum"
        case .lockIn: return "Lock In"
        case .brown: return "Deep Noise"
        case .binaural: return "Focus Beats 40 Hz"
        case .custom: return "Custom Audio"
        }
    }

    var isDrone: Bool {
        switch self {
        case .humTide, .humSweep, .droneChorus, .droneFifth, .warmHybrid: return true
        default: return false
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
    private var playerFadeTimer: Timer?
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var brownL: Float = 0
    private var brownR: Float = 0
    private var lpL: Float = 0        // one-pole low-pass state — darkens the noise into a soft rumble
    private var lpR: Float = 0
    private var phaseL: Double = 0
    private var phaseR: Double = 0
    private var padRenderer: PadRenderer?
    private var droneRenderer: DroneRenderer?
    private var lockInRenderer: LockInRenderer?
    private var sampleIndex: Double = 0
    /// Session-relative clock for section schedules and slow LFOs: away stop/start cycles restart
    /// the engine (sampleIndex resets), but the soundscape must continue from where the SESSION is —
    /// otherwise LOCK IN replays its intro after every away trip and s2/s3 are never reached.
    private var sessionAnchor: Date?
    private var scheduleOffset: Double = 0
    private var fade: Float = 0       // 0→1 ramp; applied SQUARED so the swell feels gradual
    private var targetGain: Float = 0.1
    private var mode: FocusSoundMode = .brown

    /// Background sound must stay a whisper — hard ceiling on the effective gain regardless of slider.
    private let maxGain: Float = 0.22
    /// The music appears over this long — a slow swell, not a jump cut.
    private let fadeInSeconds = 12.0

    func start(mode: FocusSoundMode, volume: Float, customFileURL: URL? = nil) {
        if mode == .custom {
            startCustom(volume: volume, url: customFileURL)
            return
        }
        let clamped = min(volume, 1) * maxGain                   // slider 0…1 → whisper range
        guard !isPlaying else {
            let sr = engine.outputNode.inputFormat(forBus: 0).sampleRate
            prepareRenderers(for: mode, sampleRate: sr > 0 ? sr : 44_100, keepExisting: true)
            self.mode = mode
            targetGain = clamped
            return
        }
        self.mode = mode
        targetGain = clamped
        fade = 0
        brownL = 0; brownR = 0; lpL = 0; lpR = 0; phaseL = 0; phaseR = 0
        sampleIndex = 0
        if sessionAnchor == nil { sessionAnchor = Date() }      // defensive: beginSession owns this
        scheduleOffset = Date().timeIntervalSince(sessionAnchor ?? Date())

        let format = engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44_100
        prepareRenderers(for: mode, sampleRate: sampleRate, keepExisting: false)
        let fadeStep = Float(1.0 / (fadeInSeconds * sampleRate))
        let leftHz = 200.0, rightHz = 240.0                     // Δ40 Hz gamma-band beat
        let twoPi = 2.0 * Double.pi
        let lpK: Float = 0.06                                    // ~550 Hz cutoff → dark, no hiss

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                if self.fade < 1 { self.fade = min(1, self.fade + fadeStep) }
                let gain = self.targetGain * self.fade * self.fade
                self.sampleIndex += 1

                // Session-relative time: survives the engine restarts around away trips, so
                // LOCK IN sections and the slow LFOs continue instead of replaying the intro.
                let t = self.scheduleOffset + self.sampleIndex / sampleRate

                var left: Float = 0
                var right: Float = 0
                switch self.mode {
                case .pad:
                    // Our generated ambient pad (shared PadRenderer, already RMS-scaled).
                    if let out = self.padRenderer?.render(t: t) {
                        left = out.left; right = out.right
                    }
                case .humTide, .humSweep, .droneChorus, .droneFifth, .warmHybrid:
                    // Tonal drone/hum family (shared DroneRenderer, already RMS-scaled).
                    if let s = self.droneRenderer?.render(t: t) {
                        left = s; right = s
                    }
                case .lockIn:
                    // LOCK IN protocol — sections follow the session clock.
                    if let out = self.lockInRenderer?.render(t: t) {
                        left = out.left; right = out.right
                    }
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
                left = max(-1, min(1, left * gain))
                right = max(-1, min(1, right * gain))

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

    /// Anchor the session clock — called once per hyperfocus session (.startTimer), NOT on the
    /// away resume; that is what lets the soundscape continue across away stop/start cycles.
    func beginSession() { sessionAnchor = Date() }

    /// The session ended (.stopTimer) — the next session starts its arc from zero.
    func endSession() { sessionAnchor = nil }

    /// Allocate the mode's renderer ahead of time — never on the realtime render thread.
    /// `keepExisting` (live mode switch while playing) preserves an already-running renderer's
    /// phase state; a fresh start always rebuilds so every session begins from silence.
    private func prepareRenderers(for mode: FocusSoundMode, sampleRate: Double, keepExisting: Bool) {
        if mode == .pad, !(keepExisting && padRenderer != nil) {
            padRenderer = PadRenderer(sampleRate: sampleRate)
        }
        if mode.isDrone {
            // A drone renderer is mode-specific — rebuild whenever the target mode changes.
            droneRenderer = DroneRenderer(mode: mode, sampleRate: sampleRate)
        }
        if mode == .lockIn, !(keepExisting && lockInRenderer != nil) {
            lockInRenderer = LockInRenderer(sampleRate: sampleRate, schedule: LockInPhase.production(elapsed:))
        }
        if !keepExisting {
            if mode != .pad { padRenderer = nil }
            if !mode.isDrone { droneRenderer = nil }
            if mode != .lockIn { lockInRenderer = nil }
        }
    }

    /// User-picked audio: loops for the whole session, swells in over ~12 s on a squared curve
    /// (AVAudioPlayer's own fade is linear — too sudden at the start), music-level ceiling.
    private func startCustom(volume: Float, url: URL?) {
        let target = min(volume, 1) * 0.6
        guard !isPlaying else {
            player?.setVolume(target, fadeDuration: 0.5)
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
        player = p
        isPlaying = true

        let start = Date()
        let duration = fadeInSeconds
        playerFadeTimer?.invalidate()
        playerFadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak p] timer in
            guard let self, let p, self.player === p else { timer.invalidate(); return }
            let x = Float(min(1, Date().timeIntervalSince(start) / duration))
            p.volume = target * x * x
            if x >= 1 { timer.invalidate(); self.playerFadeTimer = nil }
        }
    }

    func stop() {
        guard isPlaying else { return }
        if let p = player {
            playerFadeTimer?.invalidate()
            playerFadeTimer = nil
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

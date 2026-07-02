// AlarmService.swift — AVAudioEngine brown-noise loop implementation of AlarmPlaying (canon §6).
//
// Generates soft continuous brown noise in a source-node render block (no audio assets), fades in
// over 0.8 s, and loops until stop(). Not a beep — a low hum, per BRIEF.

import AVFoundation

final class AlarmService: AlarmPlaying {
    private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var brown: Float = 0
    private var targetVolume: Float = 0.5
    private var currentGain: Float = 0          // ramped toward targetVolume for the fade-in
    private var sampleRate: Float = 44_100

    func start(volume: Float) {
        guard !isPlaying else { targetVolume = volume; return }
        targetVolume = volume
        currentGain = 0
        brown = 0

        let format = engine.outputNode.inputFormat(forBus: 0)
        sampleRate = Float(format.sampleRate > 0 ? format.sampleRate : 44_100)
        let fadeSamples = Constants.Alarm.fadeInSeconds * Double(sampleRate)
        let gainStep = Float(1.0 / max(1, fadeSamples))

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                // Brown noise: integrate white noise with a small leak (canon §6 formula).
                let white = Float.random(in: -1...1)
                self.brown += (white - self.brown * Constants.Alarm.brownNoiseIntegration)
                var sample = self.brown * Constants.Alarm.brownNoiseGain
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

// VoicePromptService.swift — plays the bundled cinematic voice clips (VoicePrompting), TTS fallback (canon §6, §13 #19).
//
// The four prompts are pre-recorded with a deep cinematic male voice (Higgsfield "Caspian", seed_audio)
// and bundled as WAVs under Resources/Voice. If a clip is ever missing, we fall back to AVSpeech so the
// app still speaks. `style` no longer changes the timbre (the clip is fixed) but is kept for the fallback.

import AVFoundation

final class VoicePromptService: VoicePrompting {
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()   // fallback only

    func speak(_ line: VoiceLine, style: VoiceStyle) {
        if let url = Self.clipURL(for: line), let player = try? AVAudioPlayer(contentsOf: url) {
            self.player?.stop()
            self.player = player
            player.prepareToPlay()
            player.play()
        } else {
            let utterance = AVSpeechUtterance(string: Constants.Copy.voiceLine(line))
            utterance.rate = Constants.Voice.rate(for: style)
            utterance.pitchMultiplier = Constants.Voice.pitchMultiplier(for: style)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
        }
    }

    func stopSpeaking() {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private static func clipURL(for line: VoiceLine) -> URL? {
        let name: String
        switch line {
        case .countdown: name = "countdown"
        case .away:      name = "away"
        case .restored:  name = "restored"
        case .complete:  name = "complete"
        }
        return Bundle.main.url(forResource: name, withExtension: "wav")
    }
}

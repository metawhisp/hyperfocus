// VoicePromptService.swift — plays the bundled cinematic voice clips (VoicePrompting), TTS fallback (canon §6, §13 #19/#21).
//
// Each persona (Caspian, Gideon — deep cinematic male voices from Higgsfield seed_audio) has its own
// four WAVs under Resources/Voice named "<persona>_<line>.wav". If a clip is missing we fall back to
// AVSpeech so the app still speaks.

import AVFoundation

final class VoicePromptService: VoicePrompting {
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()   // fallback only

    func speak(_ line: VoiceLine, persona: VoicePersona) {
        if let url = Self.clipURL(for: line, persona: persona),
           let player = try? AVAudioPlayer(contentsOf: url) {
            self.player?.stop()
            self.player = player
            player.prepareToPlay()
            player.play()
        } else {
            let utterance = AVSpeechUtterance(string: Constants.Copy.voiceLine(line))
            utterance.rate = 0.45
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
        }
    }

    func stopSpeaking() {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private static func clipURL(for line: VoiceLine, persona: VoicePersona) -> URL? {
        let lineName: String
        switch line {
        case .countdown: lineName = "countdown"
        case .away:      lineName = "away"
        case .restored:  lineName = "restored"
        case .complete:  lineName = "complete"
        }
        return Bundle.main.url(forResource: "\(persona.rawValue)_\(lineName)", withExtension: "wav")
    }
}

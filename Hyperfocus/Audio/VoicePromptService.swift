// VoicePromptService.swift — AVSpeechSynthesizer implementation of VoicePrompting (canon §6).

import AVFoundation

final class VoicePromptService: VoicePrompting {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ line: VoiceLine, style: VoiceStyle) {
        let utterance = AVSpeechUtterance(string: Constants.Copy.voiceLine(line))
        utterance.rate = Constants.Voice.rate(for: style)
        utterance.pitchMultiplier = Constants.Voice.pitchMultiplier(for: style)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

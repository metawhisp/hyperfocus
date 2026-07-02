// VoicePrompting.swift — contract for spoken voice prompts (canon §6, §13 #19/#21).

import Foundation

protocol VoicePrompting: AnyObject {
    func speak(_ line: VoiceLine, persona: VoicePersona)
    func stopSpeaking()
}

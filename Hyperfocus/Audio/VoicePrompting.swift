// VoicePrompting.swift — contract for spoken voice prompts (canon §6).

import Foundation

protocol VoicePrompting: AnyObject {
    func speak(_ line: VoiceLine, style: VoiceStyle)
    func stopSpeaking()
}

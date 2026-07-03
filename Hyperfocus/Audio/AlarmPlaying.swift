// AlarmPlaying.swift — contract for the looping away-mode alarm (canon §6).

import Foundation

protocol AlarmPlaying: AnyObject {
    func start(volume: Float)
    func start(volume: Float, sound: AlarmSound)
    func stop()
    var isPlaying: Bool { get }
}

extension AlarmPlaying {
    /// Conformers that don't care about the sound (test doubles) fall back to the plain start.
    func start(volume: Float, sound: AlarmSound) { start(volume: volume) }
}

// AlarmPlaying.swift — contract for the looping away-mode alarm (canon §6).

import Foundation

protocol AlarmPlaying: AnyObject {
    func start(volume: Float)
    func stop()
    var isPlaying: Bool { get }
}

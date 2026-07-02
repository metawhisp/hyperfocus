// SimulatedPresenceService.swift — debug PresenceDetecting implementation driven by the Debug menu (canon §10).

import Foundation

final class SimulatedPresenceService: PresenceDetecting {
    var onEvent: ((PresenceEvent) -> Void)?

    func startWarmup() { /* no hardware to warm up */ }

    func startDetection() {
        // Assume the user is present when detection begins.
        onEvent?(.facePresent)
    }

    func stop() { /* nothing to tear down */ }

    /// Called by the Debug menu items to emit simulated presence events on the main thread.
    func simulate(_ event: PresenceEvent) {
        onEvent?(event)
    }
}

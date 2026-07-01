// SimulatedPresenceService.swift — debug PresenceDetecting implementation driven by the Debug menu (canon §10).

import Foundation

final class SimulatedPresenceService: PresenceDetecting {
    var onEvent: ((PresenceEvent) -> Void)?

    func startWarmup() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
    }

    func startDetection() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
    }

    func stop() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
    }

    /// Called by the Debug menu items to emit simulated presence events.
    func simulate(_ event: PresenceEvent) {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 7
    }
}

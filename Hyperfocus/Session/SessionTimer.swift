// SessionTimer.swift — 1 Hz tick source with monotonic-clock deltas (canon §4).

import Foundation

final class SessionTimer {
    /// Called on the main run loop with the monotonic delta since the previous tick.
    var onTick: ((_ deltaSeconds: Double) -> Void)?

    func start() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 6
    }

    func stop() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 6
    }
}

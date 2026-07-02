// SessionTimer.swift — 1 Hz tick source with monotonic-clock deltas (canon §4).
//
// Emits the elapsed monotonic seconds since the previous tick, so wall-clock changes and machine
// sleep are handled correctly (a 10-minute sleep surfaces as one large delta the reducer clamps).
// The now-source is injectable for deterministic tests; production uses CACurrentMediaTime()
// (mach_absolute_time-based, monotonic). Clamping large gaps is the reducer's job, not the timer's.

import Foundation
import QuartzCore

final class SessionTimer {
    /// Called on the main run loop with the monotonic delta since the previous tick.
    var onTick: ((_ deltaSeconds: Double) -> Void)?

    private let now: () -> Double
    private var timer: Timer?
    private var lastTick: Double?

    init(now: @escaping () -> Double = { CACurrentMediaTime() }) {
        self.now = now
    }

    /// Starts ticking at 1 Hz. Scheduled in `.common` mode so ticks keep firing during window drags.
    func start() {
        lastTick = now()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.fire() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastTick = nil
    }

    /// Computes the monotonic delta since the last tick and emits it. Called by the scheduled timer;
    /// also the injection point for unit tests driving a controlled clock. No-op while stopped.
    func fire() {
        guard timer != nil else { return }
        let current = now()
        let delta = max(0, current - (lastTick ?? current))
        lastTick = current
        onTick?(delta)
    }
}

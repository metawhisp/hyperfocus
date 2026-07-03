// OrbLifeModel.swift — schedules the idle orb's liveliness (canon #39). While the orb is idle
// it fires a RANDOM beat at a RANDOM interval (~30–60 min). The menu's "Show Focus Orb" plays
// the SPIN entrance once. Nothing fires during a session — the orb must not clown mid-focus.

import SwiftUI

final class OrbLifeModel: ObservableObject {
    struct Beat: Equatable {
        let variant: OrbLifeVariant
        let start: Date
        let dir: Double            // ±1 roll direction (orbit)
        let isEntrance: Bool
        let duration: Double
    }

    @Published private(set) var beat: Beat?

    /// The orb view sets this so scheduling only fires while idle.
    var isIdle: () -> Bool = { false }

    private var scheduleTimer: Timer?
    private var clearTimer: Timer?
    private let minInterval: Double = 30 * 60
    private let maxInterval: Double = 60 * 60

    // MARK: Idle scheduling

    /// Begin the random idle-beat schedule (idempotent).
    func startIdleScheduling() {
        guard scheduleTimer == nil else { return }
        armNext()
    }

    func stopIdleScheduling() {
        scheduleTimer?.invalidate(); scheduleTimer = nil
    }

    private func armNext() {
        scheduleTimer?.invalidate()
        let delay = Double.random(in: minInterval...maxInterval)
        let t = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.isIdle() && self.beat == nil {
                self.fire(OrbLifeVariant.allCases.randomElement() ?? .blink, isEntrance: false)
            }
            self.armNext()
        }
        RunLoop.main.add(t, forMode: .common)
        scheduleTimer = t
    }

    // MARK: Entrance (menu Show Focus Orb) — always spin, once

    func playEntrance() {
        guard isIdle() else { return }   // the spin summon only makes sense over the idle orb
        fire(.spin, isEntrance: true)
    }

    /// A session started (or the orb left idle) — abort any playful beat immediately.
    func interrupt() {
        clearTimer?.invalidate(); clearTimer = nil
        if beat != nil { beat = nil }
    }

    /// DEBUG: fire a random beat immediately so the live orb can be judged without the wait.
    func debugFireRandom() { fire(OrbLifeVariant.allCases.randomElement() ?? .blink, isEntrance: false) }

    // MARK: Firing

    private func fire(_ variant: OrbLifeVariant, isEntrance: Bool) {
        let start = Date()
        let dir: Double = Bool.random() ? 1 : -1
        let dur = variant.duration + (isEntrance ? 0.3 : 0)   // entrance holds a touch longer
        let b = Beat(variant: variant, start: start, dir: dir, isEntrance: isEntrance, duration: dur)
        beat = b
        clearTimer?.invalidate()
        let ct = Timer(timeInterval: dur, repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.beat?.start == start { self.beat = nil }
        }
        RunLoop.main.add(ct, forMode: .common)
        clearTimer = ct
    }
}

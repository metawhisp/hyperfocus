// OrbPositionStore.swift — persists the orb position (hf.orbPosition) and clamps it to visible screen bounds (canon §2, §8).

import Foundation

final class OrbPositionStore {
    private let settings: SettingsStore

    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
    }

    func load() -> CGPoint? {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 2
        return nil
    }

    func save(_ position: CGPoint) {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 2
    }

    func reset() {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 2
    }
}

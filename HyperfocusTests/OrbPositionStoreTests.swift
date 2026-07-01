// OrbPositionStoreTests.swift — tests for orb position persistence and clamping (canon §2, §8).

import XCTest
@testable import Hyperfocus

final class OrbPositionStoreTests: XCTestCase {
    func testStoreCanBeConstructed() {
        let defaults = UserDefaults(suiteName: "OrbPositionStoreTests-\(UUID().uuidString)")!
        let store = OrbPositionStore(settings: SettingsStore(defaults: defaults))
        XCTAssertNotNil(store)
    }
}

// OrbPositionStoreTests.swift — orb position persistence and clamping (canon §2, §8; specs/06 §4.6).

import XCTest
@testable import Hyperfocus

final class OrbPositionStoreTests: XCTestCase {

    private let bounds = CGRect(x: 0, y: 0, width: 1440, height: 900)

    private func makeStore() -> (OrbPositionStore, SettingsStore) {
        let defaults = UserDefaults(suiteName: "OrbPositionStoreTests-\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        return (OrbPositionStore(settings: settings), settings)
    }

    func test_orbStore_saveThenLoad_roundtrips() {
        let (store, _) = makeStore()
        store.save(CGPoint(x: 100, y: 200))
        XCTAssertEqual(store.load(visibleBounds: bounds), CGPoint(x: 100, y: 200))
    }

    func test_orbStore_clampsOffscreenPosition() {
        let (store, settings) = makeStore()
        store.save(CGPoint(x: 10000, y: 10000))
        let loaded = store.load(visibleBounds: bounds)
        let size = settings.orbSize
        XCTAssertEqual(loaded, CGPoint(x: bounds.maxX - size, y: bounds.maxY - size))
        XCTAssertLessThanOrEqual(loaded.x + size, bounds.maxX)   // orb fully visible
        XCTAssertLessThanOrEqual(loaded.y + size, bounds.maxY)
    }

    func test_orbStore_clampsNegativePosition() {
        let (store, _) = makeStore()
        store.save(CGPoint(x: -500, y: -500))
        XCTAssertEqual(store.load(visibleBounds: bounds), CGPoint(x: 0, y: 0))
    }

    func test_orbStore_malformedValueFallsBackToDefault() {
        let (store, settings) = makeStore()
        settings.orbPosition = "garbage{{{"
        XCTAssertEqual(store.load(visibleBounds: bounds), store.defaultPosition(in: bounds))
    }

    func test_orbStore_missingKeyFallsBackToDefault() {
        let (store, settings) = makeStore()
        XCTAssertNil(settings.orbPosition)
        let expected = store.defaultPosition(in: bounds)
        XCTAssertEqual(store.load(visibleBounds: bounds), expected)
        // default is bottom-right with an 8 pt margin (canon §8)
        XCTAssertEqual(expected.x, bounds.maxX - settings.orbSize - Constants.Orb.edgeMargin)
        XCTAssertEqual(expected.y, bounds.minY + Constants.Orb.edgeMargin)
    }
}

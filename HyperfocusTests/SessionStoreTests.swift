// SessionStoreTests.swift — JSON persistence roundtrip tests for SessionStore (canon §7).

import XCTest
@testable import Hyperfocus

final class SessionStoreTests: XCTestCase {
    private var directoryURL: URL!

    override func setUpWithError() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("HyperfocusTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    func testAppendThenReloadRoundtrip() throws {
        let session = Session(
            id: UUID(),
            mission: "Write landing page draft",
            successCondition: "Draft saved",
            plannedDurationSeconds: 1500,
            activeFocusSeconds: 1400,
            pausedSeconds: 100,
            breakCount: 1,
            longestStreakSeconds: 900,
            completionStatus: .done,
            startedAt: Date(timeIntervalSince1970: 1_720_000_000),
            endedAt: Date(timeIntervalSince1970: 1_720_001_500),
            intensity: .cinematic,
            cameraEnabled: true,
            nextAction: "Review with fresh eyes"
        )

        let store = SessionStore(directoryURL: directoryURL)
        try store.append(session)

        let reloaded = SessionStore(directoryURL: directoryURL)
        XCTAssertEqual(reloaded.all(), [session])
    }
}

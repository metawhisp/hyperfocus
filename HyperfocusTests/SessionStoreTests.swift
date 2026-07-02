// SessionStoreTests.swift — JSON persistence of [Session] (canon §7; specs/06 §4.5).
// All tests use an injected temp directory, never the real Application Support path.

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

    // Whole-second dates so ISO8601 encoding round-trips exactly.
    private func makeSession(
        mission: String = "Write landing page draft",
        successCondition: String? = "Draft saved",
        status: CompletionStatus = .done,
        nextAction: String? = "Review with fresh eyes",
        endedAt: Date? = Date(timeIntervalSince1970: 1_720_001_500)
    ) -> Session {
        Session(
            id: UUID(),
            mission: mission,
            successCondition: successCondition,
            plannedDurationSeconds: 1500,
            activeFocusSeconds: 1400,
            pausedSeconds: 100,
            breakCount: 1,
            longestStreakSeconds: 900,
            completionStatus: status,
            startedAt: Date(timeIntervalSince1970: 1_720_000_000),
            endedAt: endedAt,
            intensity: .cinematic,
            cameraEnabled: true,
            nextAction: nextAction
        )
    }

    func test_store_appendThenAll_roundtripsAllFields() throws {
        let session = makeSession(status: .partial)
        let store = SessionStore(directoryURL: directoryURL)
        try store.append(session)
        let reloaded = SessionStore(directoryURL: directoryURL)
        XCTAssertEqual(reloaded.all(), [session])
    }

    func test_store_optionalFieldsNil_roundtrip() throws {
        let session = makeSession(successCondition: nil, nextAction: nil, endedAt: nil)
        let store = SessionStore(directoryURL: directoryURL)
        try store.append(session)
        let reloaded = SessionStore(directoryURL: directoryURL).all()
        XCTAssertEqual(reloaded, [session])
        XCTAssertNil(reloaded.first?.successCondition)
        XCTAssertNil(reloaded.first?.nextAction)
        XCTAssertNil(reloaded.first?.endedAt)
    }

    func test_store_corruptFileRecoversAsEmpty() throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent(Constants.Storage.fileName)
        try "not-json{{{".data(using: .utf8)!.write(to: fileURL)

        let store = SessionStore(directoryURL: directoryURL)
        XCTAssertEqual(store.all(), [])                 // recovers as empty, no crash

        try store.append(makeSession())                 // append rewrites a valid file
        XCTAssertEqual(SessionStore(directoryURL: directoryURL).all().count, 1)
    }

    func test_store_missingDirectoryIsCreated() throws {
        let nested = directoryURL.appendingPathComponent("a/b/c", isDirectory: true)
        let store = SessionStore(directoryURL: nested)
        try store.append(makeSession())
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: nested.appendingPathComponent(Constants.Storage.fileName).path))
    }

    func test_store_clear_emptiesListAndFile() throws {
        let store = SessionStore(directoryURL: directoryURL)
        try store.append(makeSession())
        try store.append(makeSession())
        try store.append(makeSession())
        try store.clear()
        XCTAssertEqual(store.all(), [])
        XCTAssertEqual(SessionStore(directoryURL: directoryURL).all(), [])
    }

    func test_store_appendPreservesOrder() throws {
        let a = makeSession(mission: "first")
        let b = makeSession(mission: "second")
        let c = makeSession(mission: "third")
        let store = SessionStore(directoryURL: directoryURL)
        try store.append(a); try store.append(b); try store.append(c)
        XCTAssertEqual(store.all().map(\.mission), ["first", "second", "third"])
    }
}

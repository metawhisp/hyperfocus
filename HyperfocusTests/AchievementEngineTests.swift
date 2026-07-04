// AchievementEngineTests.swift — the 100-entry catalog evaluation (canon #41).

import XCTest
@testable import Hyperfocus

final class AchievementEngineTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)

    private func s(_ start: Date, focus: Int = 1500, planned: Int = 1500, breaks: Int = 0,
                   mission: String = "Write the report", status: CompletionStatus = .done,
                   camera: Bool = true, intensity: Intensity = .cinematic,
                   longest: Int = 0, paused: Int = 0, endMin: Int? = nil) -> Session {
        var end = start.addingTimeInterval(Double(focus))
        if let em = endMin {
            end = cal.date(bySettingHour: cal.component(.hour, from: start), minute: em, second: 0, of: start)!
        }
        return Session(id: UUID(), mission: mission, successCondition: nil, plannedDurationSeconds: planned,
                       activeFocusSeconds: focus, pausedSeconds: paused, breakCount: breaks,
                       longestStreakSeconds: longest, completionStatus: status, startedAt: start,
                       endedAt: end, intensity: intensity, cameraEnabled: camera, nextAction: nil)
    }
    private func d(_ y: Int, _ m: Int, _ day: Int, _ h: Int = 10) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: day, hour: h))!
    }
    private func ids(_ history: [Session], now: Date) -> Set<String> {
        AchievementEngine.unlockedIDs(history: history, now: now, calendar: cal)
    }

    func test_firstSessionAlwaysUnlocksFirstLight() {
        let got = ids([s(d(2026, 3, 10))], now: d(2026, 3, 10, 12))
        XCTAssertTrue(got.contains("first_light"))
        XCTAssertTrue(got.contains("laser_mind"))            // zero drifts
        XCTAssertTrue(got.contains("eye_contact"))           // camera on
    }

    func test_emptyHistoryUnlocksNothing() {
        XCTAssertTrue(ids([], now: d(2026, 3, 10)).isEmpty)
        XCTAssertTrue(ids([s(d(2026, 3, 10), status: .exited)], now: d(2026, 3, 10)).isEmpty)
    }

    func test_timeOfDayWindows() {
        XCTAssertTrue(ids([s(d(2026, 3, 10, 5))], now: d(2026, 3, 10, 6)).contains("early_bird"))
        XCTAssertTrue(ids([s(d(2026, 3, 10, 2))], now: d(2026, 3, 10, 6)).contains("night_owl"))
        XCTAssertTrue(ids([s(d(2026, 3, 10, 3))], now: d(2026, 3, 10, 6)).contains("witching_hour"))
    }

    func test_streaksByLongestRun() {
        let hist = [10, 11, 12].map { s(d(2026, 3, $0)) }
        XCTAssertTrue(ids(hist, now: d(2026, 3, 12, 12)).contains("streak_3"))
        XCTAssertFalse(ids(hist, now: d(2026, 3, 12, 12)).contains("streak_7"))
    }

    func test_cleanRunInTheZone() {
        let hist = (1...5).map { s(d(2026, 3, $0), breaks: 0) }
        XCTAssertTrue(ids(hist, now: d(2026, 3, 6)).contains("in_the_zone"))
        let broken = [s(d(2026, 3, 1), breaks: 0), s(d(2026, 3, 2), breaks: 1)] + (3...6).map { s(d(2026, 3, $0), breaks: 0) }
        XCTAssertFalse(ids(broken, now: d(2026, 3, 7)).contains("in_the_zone"))  // only 4 in a row
    }

    func test_durationAndMissionRules() {
        XCTAssertTrue(ids([s(d(2026, 3, 1), focus: 45 * 60)], now: d(2026, 3, 1, 12)).contains("deep_45"))
        XCTAssertTrue(ids([s(d(2026, 3, 1), mission: "ship the release")], now: d(2026, 3, 1, 12)).contains("shipmate"))
        XCTAssertTrue(ids([s(d(2026, 3, 1), mission: "написать отчёт")], now: d(2026, 3, 1, 12)).contains("polyglot"))
        XCTAssertTrue(ids([s(d(2026, 3, 1), mission: "Focus")], now: d(2026, 3, 1, 12)).contains("blank_canvas"))
    }

    func test_flawlessRequiresPerfectSession() {
        let perfect = s(d(2026, 3, 1), focus: 1500, planned: 1500, breaks: 0, paused: 0)
        XCTAssertTrue(ids([perfect], now: d(2026, 3, 1, 12)).contains("flawless"))
        let paused = s(d(2026, 3, 1), focus: 1500, planned: 1500, breaks: 0, paused: 60)
        XCTAssertFalse(ids([paused], now: d(2026, 3, 1, 12)).contains("flawless"))
    }

    func test_catalogIdsAreAllRecognized() {
        // Every id the engine can emit must exist in the catalog (no orphans).
        let catalog = Set(AchievementCatalog.all.map { $0.id })
        let emitted = ids((1...30).map { s(d(2026, 3, min($0, 28)), breaks: $0 % 4) }, now: d(2026, 4, 1))
        XCTAssertTrue(emitted.isSubset(of: catalog), "engine emitted ids not in catalog: \(emitted.subtracting(catalog))")
    }
}

// StatsServiceTests.swift — the focus-stats aggregator over session history (canon #41).

import XCTest
@testable import Hyperfocus

final class StatsServiceTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)

    private func session(_ start: Date, focus: Int, breaks: Int = 0,
                         status: CompletionStatus = .done) -> Session {
        Session(id: UUID(), mission: "m", successCondition: nil, plannedDurationSeconds: focus,
                activeFocusSeconds: focus, pausedSeconds: 0, breakCount: breaks,
                longestStreakSeconds: focus, completionStatus: status, startedAt: start,
                endedAt: start.addingTimeInterval(Double(focus)), intensity: .calm,
                cameraEnabled: true, nextAction: nil)
    }

    private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func test_onlyEarlyStopsAreExcluded() {
        // Any timer-completed session counts (done/partial/notDone); only an early STOP does not.
        let now = day(2026, 3, 15)
        let history = [
            session(day(2026, 3, 15), focus: 1500),                   // done
            session(day(2026, 3, 15), focus: 600, status: .notDone),  // counts (they focused)
            session(day(2026, 3, 15), focus: 900, status: .exited),   // excluded (early stop)
        ]
        let s = StatsService.compute(from: history, now: now, calendar: cal)
        XCTAssertEqual(s.sessionCount, 2)
        XCTAssertEqual(s.totalFocusSeconds, 2100)
    }

    func test_currentStreak_countsConsecutiveDays() {
        let now = day(2026, 3, 15)
        let history = [day(2026, 3, 13), day(2026, 3, 14), day(2026, 3, 15)].map { session($0, focus: 600) }
        let s = StatsService.compute(from: history, now: now, calendar: cal)
        XCTAssertEqual(s.currentStreakDays, 3)
    }

    func test_currentStreak_aliveIfTodayEmptyButYesterday() {
        let now = day(2026, 3, 15)
        let history = [day(2026, 3, 13), day(2026, 3, 14)].map { session($0, focus: 600) }
        let s = StatsService.compute(from: history, now: now, calendar: cal)
        XCTAssertEqual(s.currentStreakDays, 2)   // today has none yet, but the streak isn't dead
    }

    func test_currentStreak_brokenByGap() {
        let now = day(2026, 3, 15)
        let history = [day(2026, 3, 10), day(2026, 3, 15)].map { session($0, focus: 600) }
        let s = StatsService.compute(from: history, now: now, calendar: cal)
        XCTAssertEqual(s.currentStreakDays, 1)
    }

    func test_longestStreak_findsBestRun() {
        let now = day(2026, 3, 20)
        let dates = [1, 2, 3, 4, 10, 11].map { day(2026, 3, $0) }   // best run = 4
        let s = StatsService.compute(from: dates.map { session($0, focus: 600) }, now: now, calendar: cal)
        XCTAssertEqual(s.longestStreakDays, 4)
    }

    func test_laserRate_isCleanShare() {
        let now = day(2026, 3, 15)
        let history = [
            session(day(2026, 3, 15), focus: 600, breaks: 0),
            session(day(2026, 3, 15), focus: 600, breaks: 0),
            session(day(2026, 3, 15), focus: 600, breaks: 2),
            session(day(2026, 3, 15), focus: 600, breaks: 1),
        ]
        let s = StatsService.compute(from: history, now: now, calendar: cal)
        XCTAssertEqual(s.laserRate, 0.5, accuracy: 0.001)
    }

    func test_bestHour_isMostCommonStartHour() {
        let now = day(2026, 3, 15)
        let history = [
            session(day(2026, 3, 12, 10), focus: 600),
            session(day(2026, 3, 13, 10), focus: 600),
            session(day(2026, 3, 14, 15), focus: 600),
        ]
        let s = StatsService.compute(from: history, now: now, calendar: cal)
        XCTAssertEqual(s.bestHour, 10)
    }

    func test_emptyHistory_isZeroed() {
        let s = StatsService.compute(from: [], now: day(2026, 3, 15), calendar: cal)
        XCTAssertEqual(s.sessionCount, 0)
        XCTAssertEqual(s.currentStreakDays, 0)
        XCTAssertEqual(s.longestStreakDays, 0)
        XCTAssertNil(s.bestHour)
        XCTAssertEqual(s.laserRate, 0)
    }

    func test_catalog_hasExactly100UniqueIDs() {
        XCTAssertEqual(AchievementCatalog.total, 100)
        XCTAssertEqual(Set(AchievementCatalog.all.map { $0.id }).count, 100)
    }
}

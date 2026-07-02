// SessionTimerTests.swift — tests for the 1 Hz monotonic tick source (canon §4, specs/06 §4.4).

import XCTest
@testable import Hyperfocus

final class SessionTimerTests: XCTestCase {

    func test_timer_deltaComputedFromMonotonicClock() {
        var clock = 0.0
        let timer = SessionTimer(now: { clock })
        var deltas: [Double] = []
        timer.onTick = { deltas.append($0) }
        timer.start()                    // baseline 0
        clock = 1.0; timer.fire()
        clock = 2.0; timer.fire()
        XCTAssertEqual(deltas, [1.0, 1.0])
        timer.stop()
    }

    func test_timer_sleepGapEmitsSingleLargeDelta() {
        var clock = 0.0
        let timer = SessionTimer(now: { clock })
        var deltas: [Double] = []
        timer.onTick = { deltas.append($0) }
        timer.start()
        clock = 60.0; timer.fire()       // clamping is the reducer's job, not the timer's
        XCTAssertEqual(deltas, [60.0])
        timer.stop()
    }

    func test_timer_neverEmitsNegativeOrZeroDeltaAsNegative() {
        var clock = 10.0
        let timer = SessionTimer(now: { clock })
        var deltas: [Double] = []
        timer.onTick = { deltas.append($0) }
        timer.start()                    // baseline 10
        clock = 9.0; timer.fire()        // clock went backwards → delta clamped to 0
        XCTAssertEqual(deltas.first, 0)
        XCTAssertGreaterThanOrEqual(deltas.first ?? -1, 0)
        timer.stop()
    }

    func test_timer_stopCeasesTicks() {
        var clock = 0.0
        let timer = SessionTimer(now: { clock })
        var count = 0
        timer.onTick = { _ in count += 1 }
        timer.start()
        clock = 1.0; timer.fire()        // 1
        timer.stop()
        clock = 2.0; timer.fire()        // no-op while stopped
        XCTAssertEqual(count, 1)
    }

    func test_timer_restartResetsDeltaBaseline() {
        var clock = 0.0
        let timer = SessionTimer(now: { clock })
        var deltas: [Double] = []
        timer.onTick = { deltas.append($0) }
        timer.start()                    // baseline 0
        clock = 5.0; timer.fire()        // delta 5
        timer.stop()
        clock = 105.0                    // 100 s pass while stopped
        timer.start()                    // baseline 105
        clock = 106.0; timer.fire()      // delta 1, not 101
        XCTAssertEqual(deltas, [5.0, 1.0])
        timer.stop()
    }
}

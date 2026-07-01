// SessionTimerTests.swift — tests for the 1 Hz monotonic tick source (canon §4).

import XCTest
@testable import Hyperfocus

final class SessionTimerTests: XCTestCase {
    func testTimerCanBeConstructed() {
        let timer = SessionTimer()
        XCTAssertNil(timer.onTick)
    }
}

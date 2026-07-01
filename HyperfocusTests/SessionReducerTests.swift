// SessionReducerTests.swift — unit tests for the pure session state machine (canon §4–5).

import XCTest
@testable import Hyperfocus

final class SessionReducerTests: XCTestCase {
    func testInitialContextStateIsIdle() {
        let ctx = SessionContext()
        XCTAssertEqual(ctx.state, .idle)
    }
}

// SessionReducer.swift — PURE synchronous state machine: (inout SessionContext, SessionEvent) -> [SessionEffect] (canon §4–5).

import Foundation

struct SessionReducer {
    static func reduce(_ ctx: inout SessionContext, _ event: SessionEvent) -> [SessionEffect] {
        // IMPLEMENT — Phases 3–9 (T1–T3 in Phase 3, T4–T5 in Phase 4, T13–T16/T18 in Phase 6, T6–T12 in Phase 8, T17 in Phase 9) — see specs/05-implementation-plan.md
        return []
    }
}

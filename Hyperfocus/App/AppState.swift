// AppState.swift — ObservableObject root: owns the session context, coordinator, and services (canon §2).

import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var context = SessionContext()

    /// Dispatches an event through the reducer and hands effects to the coordinator.
    func send(_ event: SessionEvent) {
        // IMPLEMENT — see specs/05-implementation-plan.md Phase 1
    }
}

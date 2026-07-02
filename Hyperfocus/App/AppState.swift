// AppState.swift — ObservableObject root: owns the session context, coordinator, and services (canon §2).
//
// The single source of truth for the UI. Every event flows event → SessionReducer → effects →
// SessionCoordinator. The reducer stays pure, so this layer stamps session timestamps and persists.

import SwiftUI
import AppKit
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var context = SessionContext()
    @Published var useSimulatedCamera = false

    let settings = SettingsStore()
    let store = SessionStore()
    private let coordinator: SessionCoordinator
    private var didBootstrap = false

    init() {
        coordinator = SessionCoordinator(settings: settings, store: store)
        #if DEBUG
        useSimulatedCamera = true    // debug builds default to the simulated camera (no permission prompt)
        #endif
        coordinator.attach(self)
    }

    /// Called once from AppDelegate.applicationDidFinishLaunching.
    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true
        if settings.showOrbOnLaunch { coordinator.showOrb() }
        if !settings.onboardingCompleted { coordinator.showOnboarding() }
    }

    /// Dispatch an event through the reducer, then hand the effects to the coordinator.
    func send(_ event: SessionEvent) {
        if case .enterHyperfocus = event {
            // Snapshot user-tunable thresholds into the context at session start (canon §8).
            context.warningThresholdSeconds = Double(settings.warningThresholdSeconds)
            context.awayThresholdSeconds = Double(settings.awayThresholdSeconds)
            context.recoverySeconds = Double(settings.recoverySeconds)
        }
        let effects = SessionReducer.reduce(&context, event)
        coordinator.perform(effects)
    }

    // MARK: Coordinator callbacks (keep the reducer pure — timestamps + persistence live here)

    func markTimerStarted() { if context.sessionStartTime == nil { context.sessionStartTime = Date() } }
    func markSessionEnded() { context.sessionEndTime = Date() }

    func persist(_ status: CompletionStatus) {
        let c = context
        let session = Session(
            id: UUID(),
            mission: c.config?.mission ?? "",
            successCondition: c.config?.successCondition,
            plannedDurationSeconds: c.config?.plannedDurationSeconds ?? 0,
            activeFocusSeconds: Int(c.activeFocusSeconds.rounded()),
            pausedSeconds: Int(c.pausedSeconds.rounded()),
            breakCount: c.breakCount,
            longestStreakSeconds: Int(c.longestStreakSeconds.rounded()),
            completionStatus: status,
            startedAt: c.sessionStartTime ?? Date(),
            endedAt: c.sessionEndTime ?? Date(),
            intensity: c.config?.intensity ?? .cinematic,
            cameraEnabled: c.config?.cameraEnabled ?? false,
            nextAction: c.nextAction
        )
        do { try store.append(session) }
        catch { NSLog("Hyperfocus: failed to save session: \(error.localizedDescription)") }
    }

    // MARK: Menu / UI actions

    func showOrb() { coordinator.showOrb() }
    func showSettings() { coordinator.showSettings() }
    func showHistory() { coordinator.showHistory() }

    func quit() {
        if context.state.isRunning { send(.userExited) }
        NSApp.terminate(nil)
    }

    // MARK: Debug simulation (canon §10)

    func simulatePresent() { send(.facePresenceChanged(true)) }
    func simulateMissing() { send(.facePresenceChanged(false)) }
    func simulateReturn() { send(.facePresenceChanged(true)) }
    func simulateJumpToAway() {
        guard context.state == .active || context.state == .warning else { return }
        context.lastFacePresent = false
        context.faceMissingSeconds = context.awayThresholdSeconds
        send(.tick(deltaSeconds: 1))
    }

    #if DEBUG
    /// Populate the context for headless snapshot rendering (DebugSnapshots only).
    func setContextForPreview(_ ctx: SessionContext) { context = ctx }
    #endif
}

extension SessionState {
    /// True while a session is live (countdown through the running states).
    var isRunning: Bool {
        switch self {
        case .countdown, .active, .warning, .away, .recovering, .manualPaused: return true
        default: return false
        }
    }
}

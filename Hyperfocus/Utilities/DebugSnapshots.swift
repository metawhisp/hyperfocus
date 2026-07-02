// DebugSnapshots.swift — DEBUG-only: renders key SwiftUI screens to PNGs via ImageRenderer so the UI
// can be verified headlessly (no Screen Recording permission needed). Triggered by HF_SNAPSHOT=1.
// Not part of the shipping app; compiled out of release builds.

#if DEBUG
import SwiftUI
import AppKit

@MainActor
enum DebugSnapshots {
    static func renderAll(app: AppState) {
        let dir = URL(fileURLWithPath:
            ProcessInfo.processInfo.environment["HF_SNAPSHOT_DIR"] ?? NSTemporaryDirectory())
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        snap(FocusOrbView().environmentObject(app), "orb", dir, CGSize(width: 96, height: 96))

        snap(StartSessionView(onStart: { _ in }, onCancel: {}).environmentObject(app),
             "start_card", dir, CGSize(width: 392, height: 470))

        snap(CountdownPreview(), "countdown", dir, CGSize(width: 620, height: 360))

        snap(ActiveHUDView(onExit: {}).environmentObject(previewApp(mission: "Write landing page draft",
                                                                     remaining: 1122, state: .active)),
             "hud", dir, CGSize(width: 300, height: 190))

        snap(AwayModeView(onReturn: {}, onExit: {}).environmentObject(app),
             "away_card", dir, CGSize(width: 360, height: 240))

        snap(CompletionView(onResult: { _, _ in })
                .environmentObject(previewApp(mission: "Write landing page draft",
                                              remaining: 0, state: .completed,
                                              focus: 1500, paused: 96, breaks: 2, streak: 615)),
             "completion_card", dir, CGSize(width: 384, height: 440))

        snap(OnboardingView(requestCamera: { $0(true) }, requestScreen: { $0(true) }, onFinish: {}),
             "onboarding", dir, CGSize(width: 480, height: 440))

        snap(SettingsView(onClearData: {}, onResetOrb: {}, onOpenSystemCamera: {}).environmentObject(app),
             "settings", dir, CGSize(width: 460, height: 560))

        NSLog("Hyperfocus: snapshots written to \(dir.path)")
    }

    /// A throwaway AppState with a populated context so HUD/completion snapshots show real numbers.
    private static func previewApp(mission: String, remaining: Double, state: SessionState,
                                   focus: Double = 0, paused: Double = 0,
                                   breaks: Int = 0, streak: Double = 0) -> AppState {
        let a = AppState()
        var ctx = SessionContext()
        ctx.state = state
        ctx.config = SessionConfig(mission: mission, successCondition: nil,
                                   plannedDurationSeconds: 1500, intensity: .cinematic, cameraEnabled: true)
        ctx.remainingFocusTime = remaining
        ctx.activeFocusSeconds = focus
        ctx.pausedSeconds = paused
        ctx.breakCount = breaks
        ctx.longestStreakSeconds = streak
        a.setContextForPreview(ctx)
        return a
    }

    private static func snap(_ view: some View, _ name: String, _ dir: URL, _ size: CGSize) {
        let content = ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.09)
            view
        }
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            NSLog("Hyperfocus: failed to render snapshot \(name)")
            return
        }
        try? png.write(to: dir.appendingPathComponent("\(name).png"))
    }
}

/// Static mid-countdown frame for the snapshot (the live view animates through its sequence).
private struct CountdownPreview: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
            Text("FOCUS")
                .font(SegFont.seg14(116))
                .foregroundStyle(.white)
                .shadow(color: Palette.green.opacity(0.9), radius: 34)
                .minimumScaleFactor(0.4).lineLimit(1).padding(.horizontal, 24)
        }
    }
}
#endif

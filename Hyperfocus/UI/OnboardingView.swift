// OnboardingView.swift — activation-first onboarding (canon §13 #26): teach by doing, collect the
// first mission along the way, and end with the user INSIDE their first running session.

import SwiftUI

struct OnboardingView: View {
    var requestCamera: (@escaping (Bool) -> Void) -> Void
    var requestScreen: (@escaping (Bool) -> Void) -> Void
    /// Close onboarding and immediately start the first session with what the user typed.
    var onStartFirstSession: (String, Int) -> Void
    var onFinish: () -> Void

    @State private var step: Int
    @State private var mission: String
    @State private var minutes = 15
    @State private var cameraGranted: Bool?
    @State private var screenGranted: Bool?

    init(requestCamera: @escaping (@escaping (Bool) -> Void) -> Void,
         requestScreen: @escaping (@escaping (Bool) -> Void) -> Void,
         onStartFirstSession: @escaping (String, Int) -> Void,
         onFinish: @escaping () -> Void,
         step: Int = 0, mission: String = "") {
        self.requestCamera = requestCamera
        self.requestScreen = requestScreen
        self.onStartFirstSession = onStartFirstSession
        self.onFinish = onFinish
        _step = State(initialValue: step)
        _mission = State(initialValue: mission)
    }

    private var trimmedMission: String { mission.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 36)
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(i == step ? Palette.green : Color.white.opacity(0.18))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 480, height: 500)
        .background(Color(red: 0.055, green: 0.065, blue: 0.09))
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    @ViewBuilder private var content: some View {
        switch step {
        case 0: meetTheOrb
        case 1: firstMission
        case 2: cameraStep
        case 3: screenStep
        default: readyStep
        }
    }

    // MARK: Step 1 — meet the orb (learn the core gesture by doing it)

    private var meetTheOrb: some View {
        VStack(spacing: 14) {
            Spacer()
            Text("This is your Focus Orb")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("It lives in the corner of your screen.\nOne click starts a focus session.")
                .font(.system(size: 13)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            OrbClickDemo(onDone: { step = 1 })
            Text("Click the orb to continue")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.green)
            Spacer()
        }
    }

    // MARK: Step 2 — the first mission (collected for real use at the end)

    private var firstMission: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("One task. One session.")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("What will you focus on first?")
                .font(.system(size: 13)).foregroundStyle(.secondary)

            TextField("e.g. Write the report intro", text: $mission)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.12)))

            HStack(spacing: 8) {
                ForEach([5, 15, 25], id: \.self) { m in
                    Button("\(m) min") { minutes = m }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(minutes == m ? Palette.green : Color.white.opacity(0.07), in: Capsule())
                        .foregroundStyle(minutes == m ? .black : .primary)
                }
                Spacer()
            }
            Text("Small first session — an easy win.")
                .font(.system(size: 11)).foregroundStyle(.tertiary)

            HStack {
                Spacer()
                Button("Next") { step = 2 }
                    .buttonStyle(.borderedProminent).tint(Palette.green)
                    .keyboardShortcut(.defaultAction)
                    .disabled(trimmedMission.isEmpty)
            }
            Spacer()
        }
    }

    // MARK: Step 3 — camera (value first, then permission)

    private var cameraStep: some View {
        permissionStep(
            icon: "person.fill.viewfinder",
            title: "It notices when you drift",
            body: "Leave your Mac mid-session and the timer pauses — a gentle sound calls you back. Camera frames are analyzed on your Mac only. Nothing is recorded or uploaded, ever.",
            granted: cameraGranted,
            enableTitle: "Enable camera",
            enable: { requestCamera { granted in cameraGranted = granted; step = 3 } },
            skip: { step = 3 }
        )
    }

    // MARK: Step 4 — screen analysis

    private var screenStep: some View {
        permissionStep(
            icon: "rectangle.dashed.badge.record",
            title: "Distraction radar",
            body: "Hyperfocus can spot YouTube or a social feed on your screen and gently nudge you back to your task. Analyzed locally, never stored, never sent anywhere.",
            granted: screenGranted,
            enableTitle: "Enable screen access",
            enable: { requestScreen { granted in screenGranted = granted; step = 4 } },
            skip: { step = 4 }
        )
    }

    private func permissionStep(icon: String, title: String, body bodyText: String,
                                granted: Bool?, enableTitle: String,
                                enable: @escaping () -> Void, skip: @escaping () -> Void) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(Palette.green)
            Text(title).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(bodyText)
                .font(.system(size: 13)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            if let granted {
                Label(granted ? "Access granted" : "Not enabled",
                      systemImage: granted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(granted ? Palette.green : .secondary)
            }
            HStack(spacing: 10) {
                Button("Not now", action: skip).buttonStyle(.bordered)
                Button(enableTitle, action: enable)
                    .buttonStyle(.borderedProminent).tint(Palette.green)
                    .keyboardShortcut(.defaultAction)
            }
            Spacer()
        }
    }

    // MARK: Step 5 — recap the three gestures + start the first session NOW

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("You're set")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                gestureRow(icon: "cursorarrow.click", title: "Click the orb", detail: "start a session")
                gestureRow(icon: "hand.tap.fill", title: "Hold it", detail: "quick start with recent durations")
                gestureRow(icon: "filemenu.and.cursorarrow", title: "Right-click", detail: "pause, exit, settings")
            }
            .padding(18)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 10) {
                Button {
                    onStartFirstSession(trimmedMission.isEmpty ? "Focus" : trimmedMission, minutes)
                } label: {
                    Text("Start my first session — \(minutes) min")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Palette.green)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                if !trimmedMission.isEmpty {
                    Text("Mission: \(trimmedMission)")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Button("I'll start later", action: onFinish)
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    private func gestureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Palette.green)
                .frame(width: 24)
            Text(title).font(.system(size: 13, weight: .semibold))
            Text("— \(detail)").font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }
}

/// The live orb from step 1: sleeping red ring; the user's click powers it on (the core gesture,
/// learned by doing), then the flow advances.
private struct OrbClickDemo: View {
    var onDone: () -> Void
    @State private var clickedAt: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let now = tl.date
            let t = now.timeIntervalSinceReferenceDate
            let p: Double = {
                guard let clickedAt else { return 0 }
                return min(1, now.timeIntervalSince(clickedAt) / 0.7)
            }()
            RingToParticlesOrb(t: t, progress: p, diameter: 64,
                               brightness: 3.0 + (2.2 - 3.0) * p)
                .frame(width: 150, height: 140)
        }
        .contentShape(Circle().inset(by: 18))
        .onTapGesture {
            guard clickedAt == nil else { return }
            clickedAt = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onDone() }
        }
    }
}

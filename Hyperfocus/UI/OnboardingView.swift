// OnboardingView.swift — activation-first onboarding in FLIGHT DECK design (canon #26, #29).
// Teach by doing, collect the first mission along the way, end INSIDE the first running session.

import SwiftUI

struct OnboardingView: View {
    var requestCamera: (@escaping (Bool) -> Void) -> Void
    var requestScreen: (@escaping (Bool) -> Void) -> Void
    /// Close onboarding and immediately start the first session with what the user typed.
    var onStartFirstSession: (String, Int) -> Void
    var onFinish: () -> Void
    var onSuggest: () -> String? = { nil }   // magic wand parity with the READY? card
    /// Live re-check when the user returns from System Settings (Screen Recording grant).
    var screenAuthorized: () -> Bool = { false }

    @State private var step: Int
    @State private var mission: String
    @State private var minutes = 15
    @State private var cameraGranted: Bool?
    @State private var screenGranted: Bool?
    @State private var screenSettingsHint = false   // shown once ENABLE bounced to System Settings

    init(requestCamera: @escaping (@escaping (Bool) -> Void) -> Void,
         requestScreen: @escaping (@escaping (Bool) -> Void) -> Void,
         onStartFirstSession: @escaping (String, Int) -> Void,
         onFinish: @escaping () -> Void,
         onSuggest: @escaping () -> String? = { nil },
         screenAuthorized: @escaping () -> Bool = { false },
         step: Int = 0, mission: String = "") {
        self.requestCamera = requestCamera
        self.requestScreen = requestScreen
        self.onStartFirstSession = onStartFirstSession
        self.onFinish = onFinish
        self.onSuggest = onSuggest
        self.screenAuthorized = screenAuthorized
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
                    Circle().fill(i == step ? FD.lime : Color.white.opacity(0.15))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 18)
        }
        .frame(width: 530, height: 520)
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
                Circle().fill(FD.lime.opacity(0.15)).frame(width: 220, height: 220)
                    .blur(radius: 80).offset(x: -60, y: -70)
            }
        )
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

    // MARK: Shared step scaffold — icon slot, title and the bottom controls sit at the SAME
    // position on every step, so nothing jumps as the flow advances (user feedback).

    private func stepFrame<C: View, B: View>(icon: [String]?, iconColor: Color, title: String,
                                             @ViewBuilder content: () -> C,
                                             @ViewBuilder bottom: () -> B) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 26)
            Group {
                if let icon { PixelIcon(pattern: icon, color: iconColor, pixel: 3.2) }
            }
            .frame(height: 32)
            Text(title).font(FD.matrix(21)).foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.top, 14)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.top, 12)
            bottom()
            Spacer().frame(height: 20)
        }
    }

    /// Left-aligned value bullet: pixel icon + one plain line, stretching the card's width.
    private func bullet(_ icon: [String], _ color: Color, _ text: String) -> some View {
        HStack(spacing: 14) {
            PixelIcon(pattern: icon, color: color, pixel: 2.2)
                .frame(width: 24)
            Text(text).font(.system(size: 12.5)).foregroundStyle(.white.opacity(0.82))
            Spacer(minLength: 0)
        }
    }

    // MARK: Step 1 — meet the orb (learn the core gesture by doing it)

    private var meetTheOrb: some View {
        stepFrame(icon: nil, iconColor: FD.lime, title: "FOCUS ORB") {
            VStack(spacing: 10) {
                Text("It lives in the corner of your screen.\nOne click starts a session.")
                    .font(.system(size: 12)).foregroundStyle(FD.label)
                    .multilineTextAlignment(.center)
                OrbClickDemo(onDone: { step = 1 })
            }
        } bottom: {
            Text("CLICK THE ORB TO CONTINUE")
                .font(.system(size: 11, weight: .bold)).tracking(1.2)
                .foregroundStyle(FD.lime)
                .padding(.bottom, 10)
        }
    }

    // MARK: Step 2 — the first mission (collected for real use at the end)

    private var firstMission: some View {
        stepFrame(icon: nil, iconColor: FD.lime, title: "ONE TASK") {
            VStack(spacing: 14) {
                Text("What will you focus on first?")
                    .font(.system(size: 12)).foregroundStyle(FD.label)
                FDInset {
                    HStack(spacing: 10) {
                        TextField("e.g. Write the report intro", text: $mission)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                        Button {
                            if let s = onSuggest() { mission = s }
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(FD.lime)
                                .shadow(color: FD.lime.opacity(0.7), radius: 6)
                        }
                        .buttonStyle(HFPressStyle())
                    }
                }
                HStack(spacing: 8) {
                    ForEach([5, 15, 25], id: \.self) { m in
                        FDChip(label: "\(m)", selected: minutes == m) { minutes = m }
                    }
                }
                Text("Small first session — an easy win.")
                    .font(.system(size: 10)).foregroundStyle(FD.label)
            }
        } bottom: {
            FDPrimaryButton(title: "NEXT", fullWidth: true, disabled: trimmedMission.isEmpty) { step = 2 }
                .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: Step 3 — camera (user-picked pitch: A's bullets + B's icons, roomy layout).
    // The TCC dialog shows in place; on grant the flow moves on by itself.

    private var cameraStep: some View {
        permissionStep(
            icon: PixelIcon.target, iconColor: FD.lime,
            title: "WITHOUT CAMERA — JUST A TIMER",
            bullets: [
                (PixelIcon.target, FD.lime, "Drift noticed in seconds"),
                (PixelIcon.bolt, FD.amber, "Timer pauses the moment you leave"),
                (PixelIcon.flame, FD.redLED, "A sound pulls you back on track"),
            ],
            privacy: "All on-device. Nothing recorded, ever.",
            granted: cameraGranted,
            hint: nil,
            enableTitle: "ENABLE CAMERA",
            enable: { requestCamera { granted in
                cameraGranted = granted
                if granted { DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { step = 3 } }
            } },
            skip: { step = 3 },
            skipTitle: cameraGranted == nil ? "Not now" : "Continue"
        )
    }

    // MARK: Step 4 — screen analysis. Screen Recording can only be granted in System Settings
    // (macOS opens it itself) — say so instead of silently bouncing, and don't advance the step.

    private var screenStep: some View {
        permissionStep(
            icon: PixelIcon.bolt, iconColor: FD.amber,
            title: "DISTRACTION RADAR",
            bullets: [
                (PixelIcon.bolt, FD.amber, "Spots YouTube or a feed on your screen"),
                (PixelIcon.target, FD.lime, "Nudges you back to the task"),
            ],
            privacy: "Reads the screen on this Mac only. Never stored.",
            granted: screenGranted,
            hint: screenSettingsHint && screenGranted != true
                ? "macOS opens System Settings — switch Hyperfocus on, then come back."
                : nil,
            enableTitle: "ENABLE RADAR",
            enable: {
                screenSettingsHint = true
                requestScreen { granted in
                    screenGranted = granted
                    if granted { DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { step = 4 } }
                }
            },
            skip: { step = 4 },
            skipTitle: screenSettingsHint ? "Continue" : "Not now"
        )
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification)) { _ in
            // Back from System Settings — pick up the grant without restarting the flow.
            if screenSettingsHint && screenGranted != true && screenAuthorized() {
                screenGranted = true
            }
        }
    }

    private func permissionStep(icon: [String], iconColor: Color, title: String,
                                bullets: [([String], Color, String)],
                                privacy: String, granted: Bool?, hint: String?, enableTitle: String,
                                enable: @escaping () -> Void, skip: @escaping () -> Void,
                                skipTitle: String) -> some View {
        stepFrame(icon: icon, iconColor: iconColor, title: title) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { _, b in
                    bullet(b.0, b.1, b.2)
                }
            }
            .padding(.horizontal, 26)
        } bottom: {
            VStack(spacing: 0) {
                // Fixed status slot: the hint/granted line never shifts the buttons.
                Group {
                    if let hint {
                        Text(hint)
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(FD.amber)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    } else if let granted {
                        Label(granted ? "Access granted" : "Not enabled",
                              systemImage: granted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 11))
                            .foregroundStyle(granted ? FD.lime : FD.label)
                    }
                }
                .frame(height: 24)
                HStack(spacing: 8) {
                    FDGhostButton(title: skipTitle, action: skip)
                    FDPrimaryButton(title: enableTitle, action: enable)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 8)
                Text(privacy).font(.system(size: 10)).foregroundStyle(FD.label)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: Step 5 — recap the three gestures + start the first session NOW

    private var readyStep: some View {
        stepFrame(icon: nil, iconColor: FD.lime, title: "YOU'RE SET") {
            VStack(spacing: 12) {
                FDInset {
                    VStack(alignment: .leading, spacing: 12) {
                        gesture("cursorarrow.click", "CLICK", "start a session")
                        gesture("hand.tap.fill", "HOLD", "quick start — recent durations")
                        gesture("filemenu.and.cursorarrow", "RIGHT-CLICK", "stop, settings")
                    }
                    .frame(width: 320)
                }
                if !trimmedMission.isEmpty {
                    Text("Mission: \(trimmedMission)")
                        .font(.system(size: 10)).foregroundStyle(FD.label)
                }
            }
        } bottom: {
            VStack(spacing: 10) {
                FDPrimaryButton(title: "START FIRST SESSION — \(minutes) MIN", fullWidth: true) {
                    onStartFirstSession(trimmedMission.isEmpty ? "Focus" : trimmedMission, minutes)
                }
                .keyboardShortcut(.defaultAction)
                Button("I'll start later", action: onFinish)
                    .buttonStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundStyle(FD.label)
            }
        }
    }

    private func gesture(_ icon: String, _ name: String, _ detail: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(FD.lime).frame(width: 18)
            Text(name).font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(.white)
            Text(detail).font(.system(size: 11)).foregroundStyle(FD.label)
        }
    }
}

/// Launch-time reminder shown when camera permission is still missing after onboarding (canon #27).
struct PermissionNudgeView: View {
    let canPrompt: Bool
    var onEnable: () -> Void
    var onOpenSettings: () -> Void
    var onLater: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            PixelIcon(pattern: PixelIcon.target, color: FD.amber, pixel: 3.0)
            Text("CAMERA MAKES IT WORK").font(FD.matrix(18)).foregroundStyle(.white)
            Text("Presence detection is the core of Hyperfocus — it pauses your session when you leave and calls you back. Without camera access, sessions run as plain timers. Frames never leave your Mac.")
                .font(.system(size: 11)).foregroundStyle(FD.label)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 350)
            HStack(spacing: 8) {
                FDGhostButton(title: "Later", action: onLater)
                if canPrompt {
                    FDPrimaryButton(title: "ENABLE CAMERA", action: onEnable)
                        .keyboardShortcut(.defaultAction)
                } else {
                    FDPrimaryButton(title: "OPEN SYSTEM SETTINGS", action: onOpenSettings)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 430, height: 280)
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
                Circle().fill(FD.amber.opacity(0.15)).frame(width: 160, height: 160)
                    .blur(radius: 60).offset(x: -40, y: -50)
            }
        )
        .preferredColorScheme(.dark)
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
            RingToParticlesOrb(t: t, progress: p, diameter: 56,
                               brightness: 3.0 + (2.2 - 3.0) * p)
                .frame(width: 130, height: 120)
        }
        .contentShape(Circle().inset(by: 16))
        .onTapGesture {
            guard clickedAt == nil else { return }
            clickedAt = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onDone() }
        }
    }
}

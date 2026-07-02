// CameraPitchPreviews.swift — DEBUG-only gallery (HF_CAMERA_PREVIEW=1): three harder-selling
// variants of the onboarding ENABLE CAMERA screen. User feedback on the calm version: it should
// argue more strongly that the camera is worth enabling. All claims are product truth (7 s
// warning / 15 s away defaults) — no invented numbers. Preview-before-prod.

#if DEBUG
import SwiftUI
import AppKit

private func pitchButtons() -> some View {
    HStack(spacing: 8) {
        FDGhostButton(title: "Not now", action: {})
        FDPrimaryButton(title: "ENABLE CAMERA", action: {})
    }
}

private func privacyLine() -> some View {
    Text("All on-device. Nothing recorded, ever.")
        .font(.system(size: 10)).foregroundStyle(FD.label)
}

// MARK: Variant A — STAKES: name what you lose without it

private struct PitchStakes: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            PixelIcon(pattern: PixelIcon.target, color: FD.lime, pixel: 3.4)
                .padding(.bottom, 20)
            Text("WITHOUT CAMERA\nIT'S JUST A TIMER")
                .font(FD.matrix(19)).foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 18)
            VStack(alignment: .leading, spacing: 9) {
                stakeRow("Drift noticed in seconds — not never")
                stakeRow("Timer pauses the moment you leave")
                stakeRow("A sound pulls you back on track")
            }
            .padding(.bottom, 20)
            pitchButtons()
            privacyLine().padding(.top, 14)
            Spacer()
        }
    }

    private func stakeRow(_ text: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: 12, weight: .bold)).foregroundStyle(FD.lime)
            Text(text).font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: Variant B — LOOP: animated storyboard of the mechanic

private struct PitchLoop: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let stage = Int(t / 1.2) % 3
            VStack(spacing: 0) {
                Spacer()
                Text("HOW IT KEEPS YOU LOCKED")
                    .font(FD.matrix(19)).foregroundStyle(.white)
                    .padding(.bottom, 20)
                HStack(spacing: 10) {
                    stageCell("WATCHES", PixelIcon.target, FD.lime, active: stage == 0)
                    arrow(lit: stage >= 1)
                    stageCell("CATCHES\nDRIFT", PixelIcon.bolt, FD.amber, active: stage == 1)
                    arrow(lit: stage >= 2)
                    stageCell("PULLS YOU\nBACK", PixelIcon.flame, FD.redLED, active: stage == 2)
                }
                .padding(.bottom, 18)
                Text("Look away — warning in 7 seconds, red alert in 15.\nThe whole mechanic runs on the camera; skip it and Hyperfocus goes blind.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.bottom, 20)
                pitchButtons()
                privacyLine().padding(.top, 14)
                Spacer()
            }
        }
    }

    private func stageCell(_ name: String, _ icon: [String], _ color: Color, active: Bool) -> some View {
        VStack(spacing: 8) {
            PixelIcon(pattern: icon, color: color, pixel: 2.6)
            Text(name)
                .font(.system(size: 9, weight: .bold)).tracking(1.0)
                .foregroundStyle(active ? .white : FD.label)
                .multilineTextAlignment(.center)
        }
        .frame(width: 92, height: 84)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.30)))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(active ? color.opacity(0.7) : .white.opacity(0.05), lineWidth: 1))
        .shadow(color: active ? color.opacity(0.5) : .clear, radius: 10)
    }

    private func arrow(lit: Bool) -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(lit ? FD.lime : FD.label)
    }
}

// MARK: Variant C — CONTRACT: short, blunt, dare-style

private struct PitchContract: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let pulse = 0.75 + 0.25 * sin(t * 2.2)
            VStack(spacing: 0) {
                Spacer()
                PixelIcon(pattern: PixelIcon.target, color: FD.lime, pixel: 4.2)
                    .shadow(color: FD.lime.opacity(0.6 * pulse), radius: 12)
                    .padding(.bottom, 22)
                Text("GIVE IT EYES")
                    .font(FD.matrix(24)).foregroundStyle(.white)
                    .padding(.bottom, 16)
                Text("You hired Hyperfocus to catch you drifting.\nIt can't do that blind.")
                    .font(.system(size: 12.5)).foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, 12)
                Text("LOOK AWAY → RED ALERT IN 15 SECONDS. THAT'S THE DEAL.")
                    .font(.system(size: 9.5, weight: .bold)).tracking(1.1)
                    .foregroundStyle(FD.amber)
                    .padding(.bottom, 22)
                pitchButtons()
                privacyLine().padding(.top, 14)
                Spacer()
            }
        }
    }
}

// MARK: Gallery

struct CameraPitchGalleryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("ЭКРАН ENABLE CAMERA — 3 варианта, продают сильнее")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))
            HStack(spacing: 16) {
                cell("A · STAKES", "что теряешь без камеры — чек-лист") { PitchStakes() }
                cell("B · LOOP", "анимированная механика: следит → ловит → возвращает") { PitchLoop() }
                cell("C · CONTRACT", "коротко и дерзко: дай ему глаза") { PitchContract() }
            }
        }
        .padding(20)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func cell<V: View>(_ name: String, _ hint: String, @ViewBuilder v: () -> V) -> some View {
        VStack(spacing: 8) {
            v()
                .padding(.horizontal, 24)
                .frame(width: 430, height: 470)
                .background(
                    ZStack(alignment: .topLeading) {
                        LinearGradient(colors: [FD.deviceHi, FD.device],
                                       startPoint: .top, endPoint: .bottom)
                        FDDotGrid()
                        Circle().fill(FD.lime.opacity(0.13)).frame(width: 190, height: 190)
                            .blur(radius: 70).offset(x: -50, y: -60)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            HStack(spacing: 8) {
                Text(name).font(.system(size: 11, weight: .bold)).foregroundStyle(FD.lime)
                Text(hint).font(.system(size: 11)).foregroundStyle(FD.label)
            }
        }
    }
}

@MainActor
enum CameraPitchPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 1390, height: 560),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Camera Pitch Gallery"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: CameraPitchGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}

// MARK: READY card live preview (HF_READY_PREVIEW=1) — the real production StartSessionView,
// so the in-place CUSTOM swap can be verified interactively before shipping.

@MainActor
enum ReadyCardPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let view = StartSessionView(onStart: { _ in }, onCancel: {}, onSuggest: { "Ship the demo" })
            .environmentObject(AppState.shared)
            .padding(60)
            .background(Color.black)
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 520, height: 420),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — READY? Card (CUSTOM in place)"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: view)
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

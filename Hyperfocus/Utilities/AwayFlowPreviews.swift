// AwayFlowPreviews.swift — DEBUG-only gallery (HF_AWAY_PREVIEW=1) for the away-moment redesign:
//   1. INTERACTIVE away-card flow: hovering EXIT already counts as "user is back" (recovery
//      starts), clicking EXIT opens ARE YOU SURE? whose primary is RETURN — by then the session
//      has resumed by itself. The exit becomes a springboard back into focus.
//   2. Angry orb: yellow = grows + jitters; red = grows more, jitters harder, gets ANGRY
//      (three visual styles to pick from).
//   3. Aura ramp: the red perimeter glow swells ×3.5 over the first 7 s instead of static.
//   4. Quick-start digits contrast: black on light, white on dark (adaptive).
// Preview-before-prod: pick per section, then it ships.

#if DEBUG
import SwiftUI
import AppKit

// MARK: 1 — Interactive away flow

private struct AwayFlowDemo: View {
    enum Phase { case away, sure, resumed }
    @State private var phase: Phase = .away
    @State private var hoverExit = false
    @State private var recoveryStarted = false
    @State private var resumeAt: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { tl in
            let now = tl.date
            VStack(spacing: 10) {
                ZStack {
                    card(now)
                }
                .frame(width: 400, height: 250)
                Text(caption)
                    .font(.system(size: 10)).foregroundStyle(FD.label)
            }
            .onChange(of: now) { _, n in
                if let r = resumeAt, n >= r, phase != .resumed {
                    phase = .resumed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { reset() }
                }
            }
        }
    }

    private var caption: String {
        switch phase {
        case .away: return "наведи на EXIT SESSION — recovery стартует; кликни — второй попап"
        case .sure: return "recovery уже идёт — через 3 сек сессия вернётся сама"
        case .resumed: return "и ты снова в фокусе — выхода не случилось"
        }
    }

    private func reset() {
        phase = .away; hoverExit = false; recoveryStarted = false; resumeAt = nil
    }

    @ViewBuilder
    private func card(_ now: Date) -> some View {
        switch phase {
        case .away:
            FDCard(width: 360, glow: FD.redLED) {
                VStack(spacing: 12) {
                    Text("YOU LEFT").font(FD.matrix(22)).foregroundStyle(FD.redLED)
                    Text("Timer paused · alarm on")
                        .font(.system(size: 11)).foregroundStyle(FD.label)
                    if recoveryStarted {
                        Label("Camera sees you — resuming…", systemImage: "eye.fill")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(FD.lime)
                    } else {
                        Text(" ").font(.system(size: 11))
                    }
                    HStack(spacing: 8) {
                        // The trap: hovering EXIT = presence = recovery starts immediately.
                        FDGhostButton(title: "Exit Session") {
                            phase = .sure
                            if resumeAt == nil { resumeAt = Date().addingTimeInterval(3) }
                        }
                        .onHover { h in
                            hoverExit = h
                            if h && !recoveryStarted {
                                recoveryStarted = true
                                resumeAt = Date().addingTimeInterval(3)
                            }
                        }
                        FDPrimaryButton(title: "RETURN") {
                            phase = .resumed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { reset() }
                        }
                    }
                }
            }
        case .sure:
            FDCard(width: 360, glow: FD.amber) {
                VStack(spacing: 12) {
                    Text("ARE YOU SURE?").font(FD.matrix(20)).foregroundStyle(FD.amber)
                    Text("You're already back at the screen —\nthe session is resuming right now.")
                        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    if let r = resumeAt {
                        let left = max(0, r.timeIntervalSince(Date()))
                        Text(String(format: "resuming in %.0f…", ceil(left)))
                            .font(FD.matrix(13)).foregroundStyle(FD.lime)
                    }
                    FDPrimaryButton(title: "RETURN TO HYPERFOCUS", fullWidth: true) {
                        phase = .resumed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { reset() }
                    }
                    Button("Exit anyway") { reset() }
                        .buttonStyle(.plain)
                        .font(.system(size: 10)).foregroundStyle(FD.label)
                }
            }
        case .resumed:
            FDCard(width: 360, glow: FD.lime) {
                VStack(spacing: 10) {
                    Text("BACK IN FOCUS").font(FD.matrix(22)).foregroundStyle(FD.lime)
                    Text("The exit became the way back in.")
                        .font(.system(size: 11)).foregroundStyle(FD.label)
                }
            }
        }
    }
}

// MARK: 2 — Angry orb styles (warning → away loop)

private struct AngryOrbCell: View {
    let style: Int          // 1 shake · 2 shake+angry eyes · 3 shake+flare
    let t: Double

    var body: some View {
        // 6 s loop: 0–2.5 calm green → 2.5–4.5 warning (yellow) → 4.5–6 away (red)
        let u = t.truncatingRemainder(dividingBy: 7)
        let stage = u < 2.5 ? 0 : (u < 4.5 ? 1 : 2)
        let rgb: SIMD3<Double> = stage == 0 ? RingToParticlesOrb.onRGB
            : stage == 1 ? SIMD3(1.00, 0.72, 0.23) : SIMD3(1.00, 0.30, 0.30)
        let grow: CGFloat = stage == 0 ? 1 : (stage == 1 ? 1.15 : 1.35)
        let jitterAmp: Double = stage == 0 ? 0 : (stage == 1 ? 1.6 : 3.6)
        let jx = (sin(t * 37) + sin(t * 51) * 0.6) * jitterAmp
        let jy = (cos(t * 43) + sin(t * 59) * 0.6) * jitterAmp * 0.7
        let flare = style == 3 && stage > 0 ? 1 + 0.5 * abs(sin(t * (stage == 1 ? 6 : 11))) : 1

        ZStack {
            RingToParticlesOrb(t: t, progress: 1, diameter: 48,
                               brightness: (stage == 2 ? 3.0 : 2.6) * flare, rgbOverride: rgb)
                .frame(width: 120, height: 120)
            if style == 2 && stage > 0 {
                angryFace(stage: stage)
            }
        }
        .scaleEffect(grow)
        .offset(x: jx, y: jy)
    }

    private func angryFace(stage: Int) -> some View {
        let d: CGFloat = 48
        let tilt: Double = stage == 1 ? 12 : 26      // brows slant harder when red
        return VStack(spacing: d * 0.06) {
            HStack(spacing: d * 0.14) {
                Capsule().fill(.white).frame(width: d * 0.16, height: d * 0.05)
                    .rotationEffect(.degrees(tilt))
                Capsule().fill(.white).frame(width: d * 0.16, height: d * 0.05)
                    .rotationEffect(.degrees(-tilt))
            }
            HStack(spacing: d * 0.16) {
                Capsule().fill(.white).frame(width: d * 0.10, height: d * 0.16)
                Capsule().fill(.white).frame(width: d * 0.10, height: d * 0.16)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 1)
    }
}

// MARK: 3 — Aura ramp (static vs swelling)

private struct AuraRampCell: View {
    let ramped: Bool
    let t: Double

    var body: some View {
        // 10 s loop: red starts at 0s; ramp ×3.5 over 7 s (real-time), hold, reset.
        let u = t.truncatingRemainder(dividingBy: 10)
        let k = ramped ? 1.0 + 2.5 * min(1, u / 7) : 1.0      // 1 → 3.5
        let alpha = min(1, 0.22 * k)
        let lw = 5.0 * min(k, 2.2)                             // width grows too, capped
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.85))
            Image(systemName: "doc.richtext")
                .font(.system(size: 40)).foregroundStyle(.white.opacity(0.12))
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(red: 1, green: 0.25, blue: 0.25), lineWidth: lw)
                .blur(radius: lw * 1.6)
                .opacity(alpha)
            VStack {
                Spacer()
                Text(ramped ? String(format: "×%.1f за %.0f сек", k, min(7, u)) : "статично (сейчас)")
                    .font(.system(size: 9, weight: .bold)).foregroundStyle(FD.label)
                    .padding(.bottom, 6)
            }
        }
        .frame(width: 300, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: 4 — Quick-start digits contrast

private struct ChipContrastCell: View {
    let dark: Bool
    var body: some View {
        let fg: Color = dark ? .white : .black
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(dark ? Color.black : Color(red: 0.97, green: 0.97, blue: 0.96))
            VStack(spacing: 3) {
                Text("15").font(FD.matrix(26))
                    .foregroundStyle(fg.opacity(0.92))
                    .shadow(color: dark ? .black.opacity(0.75) : .white.opacity(0.8), radius: 3, y: 1)
                    .shadow(color: FD.lime.opacity(0.35), radius: 8)
                Text("MIN").font(.system(size: 8, weight: .bold)).tracking(1.6)
                    .foregroundStyle(fg.opacity(0.6))
            }
        }
        .frame(width: 145, height: 110)
    }
}

// MARK: Gallery

struct AwayFlowGalleryView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            HStack(alignment: .top, spacing: 22) {
                VStack(spacing: 10) {
                    section("1 · AWAY-ЛОВУШКА (интерактив)")
                    AwayFlowDemo()
                }
                VStack(spacing: 16) {
                    section("2 · ЗЛОЙ ОРБ: жёлтый дёргается, красный злится")
                    HStack(spacing: 10) {
                        angryCell("V1 · SHAKE", 1, t)
                        angryCell("V2 · ANGRY EYES", 2, t)
                        angryCell("V3 · FLARE", 3, t)
                    }
                    section("3 · АУРА РАЗГОРАЕТСЯ ×3.5 ЗА 7 СЕК")
                    HStack(spacing: 10) {
                        AuraRampCell(ramped: false, t: t)
                        AuraRampCell(ramped: true, t: t)
                    }
                    section("4 · ЦИФРЫ QUICK-START: КОНТРАСТ ПОД ФОН")
                    HStack(spacing: 10) {
                        ChipContrastCell(dark: false)
                        ChipContrastCell(dark: true)
                    }
                }
            }
            .padding(22)
        }
        .background(Color(red: 0.05, green: 0.055, blue: 0.07))
        .preferredColorScheme(.dark)
    }

    private func section(_ s: String) -> some View {
        Text(s).font(.system(size: 11, weight: .bold)).tracking(0.5).foregroundStyle(FD.lime)
    }

    private func angryCell(_ name: String, _ style: Int, _ t: Double) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5))
                AngryOrbCell(style: style, t: t)
            }
            .frame(width: 200, height: 170).clipped()
            Text(name).font(.system(size: 10, weight: .bold)).foregroundStyle(FD.label)
        }
    }
}

@MainActor
enum AwayFlowPreviewWindow {
    private static var window: NSWindow?
    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 1120, height: 700),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Away Flow / Angry Orb / Aura / Digits"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: AwayFlowGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

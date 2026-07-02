// CountdownPreviews.swift — DEBUG-only live gallery (HF_COUNTDOWN_PREVIEW=1) of intro-frame
// variants for the countdown overlay. The current "ENTER HYPERFOCUS MODE" line uses a generic
// rounded system font that clashes with the FLIGHT DECK dot-matrix identity — these are four
// on-brand replacements, each looping its real entry animation so motion can be judged too.
// Preview-before-prod: the user picks, then exactly one variant ships to CountdownOverlayView.

#if DEBUG
import SwiftUI
import AppKit

// MARK: Variant A — one line, pure dot-matrix (same treatment as the 3·2·1 digits)

private struct IntroMatrixLine: View {
    @State private var opacity = 0.0
    @State private var scale = 0.85
    @State private var alive = true

    var body: some View {
        Text("ENTER HYPERFOCUS MODE")
            .font(FD.matrix(34))
            .foregroundStyle(.white)
            .shadow(color: FD.lime.opacity(0.9), radius: 24)
            .lineLimit(1).minimumScaleFactor(0.5)
            .opacity(opacity).scaleEffect(scale)
            .onAppear { loop() }
            .onDisappear { alive = false }
    }

    private func loop() {
        guard alive else { return }
        opacity = 0; scale = 0.85
        withAnimation(.easeOut(duration: 0.4)) { opacity = 1; scale = 1.06 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeIn(duration: 0.2)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { loop() }
        }
    }
}

// MARK: Variant B — stacked hierarchy: quiet caps → huge matrix word → quiet caps

private struct IntroStacked: View {
    @State private var top = 0.0
    @State private var mid = 0.0
    @State private var bottom = 0.0
    @State private var scale = 0.92
    @State private var alive = true

    var body: some View {
        VStack(spacing: 10) {
            Text("ENTER").font(.system(size: 13, weight: .semibold)).tracking(7)
                .foregroundStyle(FD.label).opacity(top)
            Text("HYPERFOCUS").font(FD.matrix(58))
                .foregroundStyle(FD.lime)
                .shadow(color: FD.lime.opacity(0.8), radius: 28)
                .lineLimit(1).minimumScaleFactor(0.5)
                .opacity(mid).scaleEffect(scale)
            Text("MODE").font(.system(size: 13, weight: .semibold)).tracking(7)
                .foregroundStyle(FD.label).opacity(bottom)
        }
        .onAppear { loop() }
        .onDisappear { alive = false }
    }

    private func loop() {
        guard alive else { return }
        top = 0; mid = 0; bottom = 0; scale = 0.92
        withAnimation(.easeOut(duration: 0.25)) { top = 1 }
        withAnimation(.easeOut(duration: 0.45).delay(0.15)) { mid = 1; scale = 1.0 }
        withAnimation(.easeOut(duration: 0.25).delay(0.4)) { bottom = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeIn(duration: 0.2)) { top = 0; mid = 0; bottom = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { loop() }
        }
    }
}

// MARK: Variant C — boot sequence: matrix text types on with a blinking block cursor

private struct IntroBoot: View {
    private let full = "ENTER HYPERFOCUS MODE"
    @State private var shown = 0
    @State private var done = false
    @State private var cursorOn = true
    @State private var alive = true
    @State private var timers: [Timer] = []

    var body: some View {
        HStack(spacing: 2) {
            Text(String(full.prefix(shown)))
                .font(FD.matrix(30))
                .foregroundStyle(done ? FD.lime : FD.amber)
                .shadow(color: (done ? FD.lime : FD.amber).opacity(0.8), radius: 18)
            Rectangle().fill(done ? FD.lime : FD.amber)
                .frame(width: 14, height: 30)
                .opacity(cursorOn ? 0.9 : 0)
        }
        .lineLimit(1).minimumScaleFactor(0.5)
        .onAppear {
            loop()
            timers.append(Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                cursorOn.toggle()
            })
        }
        .onDisappear {
            alive = false
            timers.forEach { $0.invalidate() }
            timers.removeAll()
        }
    }

    private func loop() {
        guard alive else { return }
        shown = 0; done = false
        timers.append(Timer.scheduledTimer(withTimeInterval: 0.045, repeats: true) { t in
            guard alive else { t.invalidate(); return }
            if shown < full.count {
                shown += 1
            } else {
                t.invalidate()
                withAnimation(.easeOut(duration: 0.25)) { done = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { loop() }
            }
        })
    }
}

// MARK: Variant D — protocol chip: amber status label over the phrase in an inset panel

private struct IntroChip: View {
    @State private var opacity = 0.0
    @State private var yOffset: CGFloat = 10
    @State private var alive = true

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Circle().fill(FD.amber).frame(width: 7, height: 7)
                    .shadow(color: FD.amber.opacity(0.9), radius: 5)
                Text("PROTOCOL").font(.system(size: 11, weight: .bold)).tracking(4)
                    .foregroundStyle(FD.amber)
            }
            Text("ENTER HYPERFOCUS MODE")
                .font(FD.matrix(28))
                .foregroundStyle(.white)
                .shadow(color: FD.lime.opacity(0.75), radius: 20)
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.horizontal, 22).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.35)))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(FD.lime.opacity(0.25), lineWidth: 1))
        }
        .opacity(opacity).offset(y: yOffset)
        .onAppear { loop() }
        .onDisappear { alive = false }
    }

    private func loop() {
        guard alive else { return }
        opacity = 0; yOffset = 10
        withAnimation(.easeOut(duration: 0.4)) { opacity = 1; yOffset = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.2)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { loop() }
        }
    }
}

// MARK: Gallery

struct CountdownIntroGalleryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("ИНТРО ПЕРЕД 3·2·1 — 4 варианта в стиле FLIGHT DECK, анимация живая")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))

            Grid(horizontalSpacing: 14, verticalSpacing: 14) {
                GridRow {
                    cell("A · MATRIX", "вся фраза матричным шрифтом, как цифры") { IntroMatrixLine() }
                    cell("B · STACK", "ENTER / HYPERFOCUS / MODE — иерархия") { IntroStacked() }
                }
                GridRow {
                    cell("C · BOOT", "печатается как загрузка системы, янтарь → лайм") { IntroBoot() }
                    cell("D · PROTOCOL", "статус-чип + фраза в инсете") { IntroChip() }
                }
            }
        }
        .padding(20)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func cell<V: View>(_ name: String, _ hint: String, @ViewBuilder demo: () -> V) -> some View {
        VStack(spacing: 8) {
            ZStack {
                // Same backdrop as the real overlay: darkened screen.
                RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.82))
                RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 1)
                demo().padding(.horizontal, 12)
            }
            .frame(width: 430, height: 190)
            HStack(spacing: 8) {
                Text(name).font(.system(size: 11, weight: .bold)).foregroundStyle(FD.lime)
                Text(hint).font(.system(size: 11)).foregroundStyle(FD.label)
            }
        }
    }
}

enum CountdownPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 920, height: 560),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Countdown Intro Gallery"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: CountdownIntroGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

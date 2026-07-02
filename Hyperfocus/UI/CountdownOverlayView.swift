// CountdownOverlayView.swift — fullscreen darkened ENTER HYPERFOCUS MODE → 3 → 2 → 1 → FOCUS overlay (canon §9).

import SwiftUI

struct CountdownOverlayView: View {
    @EnvironmentObject var app: AppState
    var onFinished: () -> Void
    var onAbort: () -> Void

    @State private var index = 0
    @State private var textOpacity = 0.0
    @State private var textScale = 0.85

    private let sequence = Constants.Copy.countdownSequence

    var body: some View {
        ZStack {
            Color.black
                .opacity(app.settings.darkenScreenOnStart ? 0.82 : 0.001)
                .ignoresSafeArea()

            Text(sequence[index])
                .font(.system(size: index == 0 ? 46 : 128, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Palette.green.opacity(cinematic ? 0.9 : 0.5),
                        radius: cinematic ? 34 : 18)
                .opacity(textOpacity)
                .scaleEffect(textScale)
        }
        .contentShape(Rectangle())
        .onExitCommand { onAbort() }          // Esc aborts (T5)
        .onAppear { runStep() }
    }

    private var cinematic: Bool {
        app.settings.cinematicCountdownEnabled && (app.context.config?.intensity ?? .cinematic) == .cinematic
    }

    private func runStep() {
        let reduce = app.settings.reduceMotion
        textOpacity = 0; textScale = reduce ? 1.0 : 0.85
        withAnimation(.easeOut(duration: reduce ? 0.15 : (cinematic ? 0.4 : 0.28))) {
            textOpacity = 1; textScale = reduce ? 1.0 : 1.06
        }
        let hold = cinematic ? 0.9 : 0.75
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            withAnimation(.easeIn(duration: 0.2)) { textOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                if index + 1 < sequence.count {
                    index += 1
                    runStep()
                } else {
                    onFinished()
                }
            }
        }
    }
}

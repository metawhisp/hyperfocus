// CountdownOverlayView.swift — fullscreen darkened ENTER HYPERFOCUS MODE → 3 → 2 → 1 → FOCUS overlay (canon §9).

import SwiftUI

struct CountdownOverlayView: View {
    @EnvironmentObject var app: AppState
    var onFinished: () -> Void
    var onAbort: () -> Void
    /// Fired once when the final "FOCUS" frame appears — the start stinger rises here, after the
    /// voice has counted the numbers down, so it climaxes into the timer reveal (user request).
    var onClimax: () -> Void = {}

    @State private var index = 0
    @State private var didClimax = false
    @State private var textOpacity = 0.0
    @State private var textScale = 0.85

    private let sequence = Constants.Copy.countdownSequence

    var body: some View {
        ZStack {
            Color.black
                .opacity(app.settings.darkenScreenOnStart ? 0.82 : 0.001)
                .ignoresSafeArea()

            Text(sequence[index])
                // Every frame — intro line included — gets the dot-matrix display treatment
                // (countdown gallery variant A, user-picked); the long phrase auto-shrinks to fit.
                .font(FD.matrix(116))
                .foregroundStyle(.white)
                .shadow(color: FD.lime.opacity(cinematic ? 0.9 : 0.5),
                        radius: cinematic ? 34 : 18)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.horizontal, 24)
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

    /// Per-frame hold times. Each voice clip has its own pace — the digits follow the VOICE,
    /// never the other way around (user: speeding the voice up sounds terrible). Gideon's
    /// original clip speaks Three/Two/One/Focus at 2.25/3.25/4.3/5.55 s; frames land ~0.1 s
    /// ahead of each word (frame period = hold + 0.22 s of fade/gap).
    private var holds: [Double] {
        if app.settings.voicePromptsEnabled && app.settings.voicePersona == .gideon {
            return [1.93, 0.78, 0.83, 1.03, 1.0]
        }
        let hold = cinematic ? 0.9 : 0.75
        return Array(repeating: hold, count: sequence.count)
    }

    private func runStep() {
        // The last frame ("FOCUS") is the go moment — rise the stinger into the timer here.
        if index == sequence.count - 1 && !didClimax {
            didClimax = true
            onClimax()
        }
        let reduce = app.settings.reduceMotion
        textOpacity = 0; textScale = reduce ? 1.0 : 0.85
        withAnimation(.easeOut(duration: reduce ? 0.15 : (cinematic ? 0.4 : 0.28))) {
            textOpacity = 1; textScale = reduce ? 1.0 : 1.06
        }
        let hold = holds[min(index, holds.count - 1)]
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

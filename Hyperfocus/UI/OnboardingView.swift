// OnboardingView.swift — 5-screen first-launch onboarding flow (canon §9, BRIEF).

import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0

    private struct Screen { let title: String; let text: String }
    private let screens: [Screen] = [
        .init(title: Constants.Copy.onboarding1Title, text: Constants.Copy.onboarding1Text),
        .init(title: Constants.Copy.onboarding2Title, text: Constants.Copy.onboarding2Text),
        .init(title: Constants.Copy.onboarding3Title, text: Constants.Copy.onboarding3Text),
        .init(title: Constants.Copy.onboarding4Title, text: Constants.Copy.onboarding4Text),
    ]

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Circle()
                .fill(Palette.green)
                .frame(width: 20, height: 20)
                .shadow(color: Palette.green.opacity(0.8), radius: 16)

            if page < screens.count {
                Text(screens[page].title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(screens[page].text)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            } else {
                Text("You're ready")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(0...screens.count, id: \.self) { i in
                    Circle().fill(i == page ? Palette.green : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }

            Button(page < screens.count ? "Next" : Constants.Copy.onboarding5CTA) {
                if page < screens.count { page += 1 } else { onFinish() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.green)
            .keyboardShortcut(.defaultAction)

            Spacer().frame(height: 8)
        }
        .frame(width: 460, height: 380)
        .preferredColorScheme(.dark)
    }
}

// OnboardingView.swift — first-launch onboarding with camera + screen-analysis permission steps (canon §9, §13 #23).

import SwiftUI

struct OnboardingView: View {
    var requestCamera: (@escaping (Bool) -> Void) -> Void
    var requestScreen: (@escaping (Bool) -> Void) -> Void
    var onFinish: () -> Void

    @State private var page = 0
    @State private var cameraGranted: Bool?
    @State private var screenGranted: Bool?

    private let pageCount = 6

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            orb
            content
            Spacer()
            dots
            buttons
            Spacer().frame(height: 8)
        }
        .frame(width: 480, height: 440)
        .preferredColorScheme(.dark)
    }

    private var orb: some View {
        Circle()
            .fill(Palette.green)
            .frame(width: 20, height: 20)
            .shadow(color: Palette.green.opacity(0.8), radius: 16)
    }

    @ViewBuilder private var content: some View {
        switch page {
        case 0: text(Constants.Copy.onboarding1Title, Constants.Copy.onboarding1Text)
        case 1: text(Constants.Copy.onboarding2Title, Constants.Copy.onboarding2Text)
        case 2: text(Constants.Copy.onboarding3Title, Constants.Copy.onboarding3Text, granted: cameraGranted)
        case 3: text("Screen analysis",
                     "Hyperfocus can use local screen access to help you stay on your task. Processed on your Mac — never recorded or uploaded.",
                     granted: screenGranted)
        case 4: text(Constants.Copy.onboarding4Title, Constants.Copy.onboarding4Text)
        default: text("You're ready", "One task. One session.")
        }
    }

    private func text(_ title: String, _ body: String, granted: Bool? = nil) -> some View {
        VStack(spacing: 10) {
            Text(title).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(body)
                .font(.system(size: 14)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 380)
            if let granted {
                Label(granted ? "Access granted" : "Not enabled",
                      systemImage: granted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(granted ? Palette.green : .secondary)
            }
        }
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { i in
                Circle().fill(i == page ? Palette.green : Color.white.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }

    @ViewBuilder private var buttons: some View {
        switch page {
        case 2:
            permissionButtons(enableTitle: "Enable camera") {
                requestCamera { granted in cameraGranted = granted; advance() }
            }
        case 3:
            permissionButtons(enableTitle: "Enable screen access") {
                requestScreen { granted in screenGranted = granted; advance() }
            }
        case pageCount - 1:
            primary(Constants.Copy.onboarding5CTA) { onFinish() }
        default:
            primary("Next") { advance() }
        }
    }

    private func permissionButtons(enableTitle: String, enable: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Button("Not now") { advance() }.buttonStyle(.bordered)
            Button(enableTitle, action: enable)
                .buttonStyle(.borderedProminent).tint(Palette.green)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent).tint(Palette.green)
            .keyboardShortcut(.defaultAction)
    }

    private func advance() {
        if page < pageCount - 1 { page += 1 } else { onFinish() }
    }
}

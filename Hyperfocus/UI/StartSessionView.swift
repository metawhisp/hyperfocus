// StartSessionView.swift — FLIGHT DECK "READY?" card: mission + wand, duration chips, one lime CTA (specs/07 v2).

import SwiftUI

struct StartSessionView: View {
    @EnvironmentObject var app: AppState
    var onStart: (SessionConfig) -> Void
    var onCancel: () -> Void
    var onSuggest: () -> String? = { nil }   // magic wand: mission suggestion from screen context

    @State private var mission = ""
    @State private var selectedMinutes = Constants.Defaults.defaultDurationMinutes
    @State private var isCustom = false
    @State private var customMinutes = ""
    @FocusState private var missionFocused: Bool
    @FocusState private var customFocused: Bool

    private var trimmedMission: String { mission.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var resolvedMinutes: Int? {
        if isCustom {
            guard let m = Int(customMinutes.trimmingCharacters(in: .whitespaces)),
                  Constants.Copy.customDurationRangeMinutes.contains(m) else { return nil }
            return m
        }
        return selectedMinutes
    }

    private var canStart: Bool { !trimmedMission.isEmpty && resolvedMinutes != nil }

    var body: some View {
        FDCard(width: 380) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Text("READY?").font(FD.matrix(30)).foregroundStyle(.white)
                    Spacer()
                    FDCloseButton { onCancel() }
                }

                missionField
                durationRow

                FDPrimaryButton(title: "ENTER HYPERFOCUS", fullWidth: true,
                                disabled: !canStart) { start() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .onExitCommand { onCancel() }
        .onAppear {
            let def = app.settings.defaultDurationMinutes
            if Constants.Copy.durationPresetsMinutes.contains(def) {
                selectedMinutes = def
            } else {
                isCustom = true
                customMinutes = String(def)
            }
            DispatchQueue.main.async { missionFocused = true }   // type immediately, no extra click
        }
    }

    private var missionField: some View {
        FDInset {
            HStack(spacing: 10) {
                TextField("What are you doing?", text: $mission)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .focused($missionFocused)
                Button {
                    if let s = onSuggest() { mission = s }
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FD.lime)
                        .shadow(color: FD.lime.opacity(0.7), radius: 6)
                }
                .buttonStyle(HFPressStyle())
            }
        }
    }

    // One fixed-height slot: the chips and the custom input swap IN PLACE with a crossfade —
    // nothing below ever moves (user: "чтобы в том же самом месте появлялось, ничего не прыгало").
    // if/else (not opacity layers): an invisible TextField would stay in the key-view loop and
    // silently swallow Tab + keystrokes.
    private var durationRow: some View {
        ZStack(alignment: .leading) {
            if isCustom {
                HStack(spacing: 8) {
                    FDChip(label: "‹", selected: false) {
                        isCustom = false
                        customFocused = false
                    }
                    FDInset {
                        TextField("1–180", text: $customMinutes)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .focused($customFocused)
                            .frame(width: 56)
                    }
                    Text("MIN")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2)
                        .foregroundStyle(FD.label)
                }
                .transition(.opacity)
            } else {
                HStack(spacing: 8) {
                    ForEach(Constants.Copy.durationPresetsMinutes, id: \.self) { m in
                        FDChip(label: "\(m)", selected: selectedMinutes == m) {
                            selectedMinutes = m
                        }
                    }
                    FDChip(label: "CUSTOM", selected: false) {
                        isCustom = true
                        DispatchQueue.main.async { customFocused = true }
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(height: 38, alignment: .leading)
        .animation(.easeInOut(duration: 0.18), value: isCustom)
    }

    private func start() {
        guard let minutes = resolvedMinutes, !trimmedMission.isEmpty else { return }
        let config = SessionConfig(
            mission: trimmedMission,
            successCondition: nil,
            plannedDurationSeconds: minutes * 60,
            intensity: app.settings.defaultIntensity,
            cameraEnabled: app.settings.useCameraForPresence
        )
        onStart(config)
    }
}

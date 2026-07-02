// StartSessionView.swift — "Prepare Hyperfocus" card: mission, success condition, duration, intensity (canon §9).

import SwiftUI

struct StartSessionView: View {
    @EnvironmentObject var app: AppState
    var onStart: (SessionConfig) -> Void
    var onCancel: () -> Void

    @State private var mission = ""
    @State private var successCondition = ""
    @State private var selectedMinutes = 25
    @State private var isCustom = false
    @State private var customMinutes = ""
    @State private var intensity: Intensity = .cinematic
    @FocusState private var missionFocused: Bool

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
        GlassCard(width: 340) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Constants.Copy.startCardTitle)
                        .font(.system(size: 17, weight: .semibold))
                    Text(Constants.Copy.startCardSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                field(Constants.Copy.missionPlaceholder, text: $mission)
                    .focused($missionFocused)
                field(Constants.Copy.successPlaceholder, text: $successCondition)

                durationRow
                intensityRow

                HStack(spacing: 10) {
                    Button(Constants.Copy.startSecondaryCTA) { onCancel() }
                        .keyboardShortcut(.cancelAction)
                        .buttonStyle(.bordered)
                    Spacer()
                    Button(Constants.Copy.startPrimaryCTA) { start() }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.green)
                        .disabled(!canStart)
                }
            }
        }
        .onAppear {
            selectedMinutes = app.settings.defaultDurationMinutes
            intensity = app.settings.defaultIntensity
            DispatchQueue.main.async { missionFocused = true }   // type immediately, no extra click
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white.opacity(0.1)))
    }

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Time").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(Constants.Copy.durationPresetsMinutes, id: \.self) { m in
                    chip("\(m)", selected: !isCustom && selectedMinutes == m) {
                        isCustom = false; selectedMinutes = m
                    }
                }
                chip(Constants.Copy.customDurationLabel, selected: isCustom) { isCustom = true }
            }
            if isCustom {
                TextField("1–180", text: $customMinutes)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .frame(width: 90)
            }
        }
    }

    private var intensityRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Intensity").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(Intensity.allCases, id: \.self) { i in
                    chip(i.rawValue.capitalized, selected: intensity == i) { intensity = i }
                }
            }
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(selected ? Palette.green.opacity(0.9) : Color.white.opacity(0.07),
                            in: Capsule())
                .foregroundStyle(selected ? .black : .primary)
        }
        .buttonStyle(.plain)
    }

    private func start() {
        guard let minutes = resolvedMinutes, !trimmedMission.isEmpty else { return }
        let config = SessionConfig(
            mission: trimmedMission,
            successCondition: successCondition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil : successCondition.trimmingCharacters(in: .whitespacesAndNewlines),
            plannedDurationSeconds: minutes * 60,
            intensity: intensity,
            cameraEnabled: app.settings.useCameraForPresence
        )
        onStart(config)
    }
}

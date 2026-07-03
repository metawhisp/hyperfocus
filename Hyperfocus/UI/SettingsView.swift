// SettingsView.swift — single scrolling settings page: General / Focus / Camera / Sound / Visual / Data (canon §8).

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    var onClearData: () -> Void
    var onResetOrb: () -> Void
    var onOpenSystemCamera: () -> Void
    var onEnableScreenAnalysis: () -> Void = {}

    private var settings: SettingsStore { app.settings }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Show Focus Orb on launch",
                       isOn: boolBinding({ settings.showOrbOnLaunch }, { settings.showOrbOnLaunch = $0 }))
                LabeledContent("Orb size") {
                    Slider(value: doubleBinding({ settings.orbSize }, { settings.orbSize = $0 }),
                           in: Constants.Orb.sizeRange).frame(width: 180)
                }
                LabeledContent("Orb opacity") {
                    Slider(value: doubleBinding({ settings.orbOpacity }, { settings.orbOpacity = $0 }),
                           in: Constants.Orb.opacityRange).frame(width: 180)
                }
                Button("Reset orb position", action: onResetOrb)
            }

            Section("Focus") {
                Stepper("Default duration: \(settings.defaultDurationMinutes) min",
                        value: intBinding({ settings.defaultDurationMinutes }, { settings.defaultDurationMinutes = $0 }), in: 1...180)
                Picker("Default intensity", selection: enumBinding({ settings.defaultIntensity }, { settings.defaultIntensity = $0 })) {
                    ForEach(Intensity.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                Stepper("Warning threshold: \(settings.warningThresholdSeconds)s",
                        value: intBinding({ settings.warningThresholdSeconds }, { settings.warningThresholdSeconds = $0 }), in: 1...60)
                Stepper("Away threshold: \(settings.awayThresholdSeconds)s",
                        value: intBinding({ settings.awayThresholdSeconds }, { settings.awayThresholdSeconds = $0 }), in: 2...120)
                Stepper("Return recovery: \(settings.recoverySeconds)s",
                        value: intBinding({ settings.recoverySeconds }, { settings.recoverySeconds = $0 }), in: 1...30)
                Toggle("Allow sessions without camera",
                       isOn: boolBinding({ settings.allowSessionsWithoutCamera }, { settings.allowSessionsWithoutCamera = $0 }))
            }

            Section("Camera & screen") {
                Toggle("Use camera for presence check",
                       isOn: boolBinding({ settings.useCameraForPresence }, { settings.useCameraForPresence = $0 }))
                Toggle("Strict attention (react to looking away)",
                       isOn: boolBinding({ settings.strictAttention }, { settings.strictAttention = $0 }))
                Text("Turn off if you work on multiple monitors — glancing at a side display would count as looking away.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Toggle("Analyze screen for distractions",
                       isOn: boolBinding({ settings.useScreenAnalysis }, { settings.useScreenAnalysis = $0 }))
                HStack(spacing: 12) {
                    Button("Enable screen analysis…", action: onEnableScreenAnalysis)
                    Button("Open System camera permissions…", action: onOpenSystemCamera)
                }
                Text(Constants.Copy.privacyCopy)
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Screen analysis reads on-screen text locally to spot distractions. Frames are never recorded or uploaded.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Sound") {
                Toggle("Voice prompts", isOn: boolBinding({ settings.voicePromptsEnabled }, { settings.voicePromptsEnabled = $0 }))
                Picker("Voice", selection: enumBinding({ settings.voicePersona }, { settings.voicePersona = $0 })) {
                    ForEach(VoicePersona.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Toggle("Focus sound during sessions",
                       isOn: boolBinding({ settings.focusSoundEnabled }, { settings.focusSoundEnabled = $0 }))
                Picker("Focus sound", selection: enumBinding({ settings.focusSoundMode }, { settings.focusSoundMode = $0 })) {
                    ForEach(FocusSoundMode.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                LabeledContent("Focus sound volume") {
                    Slider(value: doubleBinding({ settings.focusSoundVolume }, { settings.focusSoundVolume = $0 }), in: 0...1).frame(width: 180)
                }
                if settings.focusSoundMode == .custom {
                    LabeledContent("Audio file") {
                        HStack(spacing: 8) {
                            Text(settings.focusSoundFile ?? "none")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                                .lineLimit(1).truncationMode(.middle).frame(maxWidth: 160, alignment: .trailing)
                            Button("Choose…") { chooseCustomAudio() }
                        }
                    }
                }
                Text("Focus Beats 40 Hz works with headphones (different tone per ear).")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Toggle("Alarm sound", isOn: boolBinding({ settings.alarmEnabled }, { settings.alarmEnabled = $0 }))
                Picker("Alarm tone", selection: enumBinding({ settings.alarmSound }, { settings.alarmSound = $0 })) {
                    ForEach(AlarmSound.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                LabeledContent("Volume") {
                    Slider(value: doubleBinding({ settings.soundVolume }, { settings.soundVolume = $0 }), in: 0...1).frame(width: 180)
                }
            }

            Section("Visual") {
                LabeledContent("Aura intensity") {
                    Slider(value: doubleBinding({ settings.auraIntensity }, { settings.auraIntensity = $0 }),
                           in: Constants.Aura.intensityRange).frame(width: 180)
                }
                LabeledContent("Aura thickness") {
                    Slider(value: doubleBinding({ settings.auraThickness }, { settings.auraThickness = $0 }),
                           in: Constants.Aura.thicknessRange).frame(width: 180)
                }
                Toggle("Reduce motion", isOn: boolBinding({ settings.reduceMotion }, { settings.reduceMotion = $0 }))
                Toggle("Darken screen on start", isOn: boolBinding({ settings.darkenScreenOnStart }, { settings.darkenScreenOnStart = $0 }))
                Toggle("Cinematic countdown", isOn: boolBinding({ settings.cinematicCountdownEnabled }, { settings.cinematicCountdownEnabled = $0 }))
            }

            Section("Data") {
                Text("Session history is stored locally on this Mac.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Button("Clear local data", role: .destructive, action: onClearData)
            }
        }
        .formStyle(.grouped)
        .tint(FD.lime)                        // FLIGHT DECK accent on toggles/sliders/pickers
        .preferredColorScheme(.dark)
        .frame(width: 460, height: 560)
    }

    /// Copy the picked audio into the sandbox container so it stays readable across launches
    /// (no security-scoped bookmarks needed).
    private func chooseCustomAudio() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let src = panel.url else { return }
        let dir = FocusSoundService.customSoundDirectory()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dest = dir.appendingPathComponent(src.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: src, to: dest)
            settings.focusSoundFile = src.lastPathComponent
            settings.focusSoundMode = .custom
            app.objectWillChange.send()
        } catch {
            NSLog("Hyperfocus: failed to import custom audio: \(error.localizedDescription)")
        }
    }

    // Bindings write through to SettingsStore (UserDefaults) and republish so the UI refreshes.
    private func boolBinding(_ get: @escaping () -> Bool, _ set: @escaping (Bool) -> Void) -> Binding<Bool> {
        Binding(get: get, set: { set($0); app.objectWillChange.send() })
    }
    private func doubleBinding(_ get: @escaping () -> Double, _ set: @escaping (Double) -> Void) -> Binding<Double> {
        Binding(get: get, set: { set($0); app.objectWillChange.send() })
    }
    private func intBinding(_ get: @escaping () -> Int, _ set: @escaping (Int) -> Void) -> Binding<Int> {
        Binding(get: get, set: { set($0); app.objectWillChange.send() })
    }
    private func enumBinding<T>(_ get: @escaping () -> T, _ set: @escaping (T) -> Void) -> Binding<T> {
        Binding(get: get, set: { set($0); app.objectWillChange.send() })
    }
}

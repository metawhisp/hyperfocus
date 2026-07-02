// SettingsView.swift — settings window: General / Focus / Camera / Sound / Visual / Data (canon §8).

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    var onClearData: () -> Void
    var onResetOrb: () -> Void
    var onOpenSystemCamera: () -> Void

    private var settings: SettingsStore { app.settings }

    var body: some View {
        TabView {
            generalTab.tabItem { Text("General") }
            focusTab.tabItem { Text("Focus") }
            cameraTab.tabItem { Text("Camera") }
            soundTab.tabItem { Text("Sound") }
            visualTab.tabItem { Text("Visual") }
            dataTab.tabItem { Text("Data") }
        }
        .frame(width: 460, height: 420)
        .padding()
    }

    // Bindings read/write SettingsStore (UserDefaults); .onChange republishes so views refresh.
    private func boolBinding(_ get: @escaping () -> Bool, _ set: @escaping (Bool) -> Void) -> Binding<Bool> {
        Binding(get: get, set: { set($0); app.objectWillChange.send() })
    }
    private func doubleBinding(_ get: @escaping () -> Double, _ set: @escaping (Double) -> Void) -> Binding<Double> {
        Binding(get: get, set: { set($0); app.objectWillChange.send() })
    }
    private func intBinding(_ get: @escaping () -> Int, _ set: @escaping (Int) -> Void) -> Binding<Int> {
        Binding(get: get, set: { set($0); app.objectWillChange.send() })
    }

    private var generalTab: some View {
        Form {
            Toggle("Show Focus Orb on launch",
                   isOn: boolBinding({ settings.showOrbOnLaunch }, { settings.showOrbOnLaunch = $0 }))
            Slider(value: doubleBinding({ settings.orbSize }, { settings.orbSize = $0 }),
                   in: Constants.Orb.sizeRange) { Text("Orb size") }
            Slider(value: doubleBinding({ settings.orbOpacity }, { settings.orbOpacity = $0 }),
                   in: Constants.Orb.opacityRange) { Text("Orb opacity") }
            Button("Reset orb position", action: onResetOrb)
        }.padding()
    }

    private var focusTab: some View {
        Form {
            Stepper("Default duration: \(settings.defaultDurationMinutes) min",
                    value: intBinding({ settings.defaultDurationMinutes }, { settings.defaultDurationMinutes = $0 }),
                    in: 1...180)
            Picker("Default intensity",
                   selection: Binding(get: { settings.defaultIntensity },
                                      set: { settings.defaultIntensity = $0; app.objectWillChange.send() })) {
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
        }.padding()
    }

    private var cameraTab: some View {
        Form {
            Toggle("Use camera for presence check",
                   isOn: boolBinding({ settings.useCameraForPresence }, { settings.useCameraForPresence = $0 }))
            Button("Open System camera permissions…", action: onOpenSystemCamera)
            Text(Constants.Copy.privacyCopy)
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }.padding()
    }

    private var soundTab: some View {
        Form {
            Toggle("Voice prompts",
                   isOn: boolBinding({ settings.voicePromptsEnabled }, { settings.voicePromptsEnabled = $0 }))
            Toggle("Alarm sound",
                   isOn: boolBinding({ settings.alarmEnabled }, { settings.alarmEnabled = $0 }))
            Slider(value: doubleBinding({ settings.soundVolume }, { settings.soundVolume = $0 }),
                   in: 0...1) { Text("Volume") }
            Picker("Voice style",
                   selection: Binding(get: { settings.voiceStyle },
                                      set: { settings.voiceStyle = $0; app.objectWillChange.send() })) {
                ForEach(VoiceStyle.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }
        }.padding()
    }

    private var visualTab: some View {
        Form {
            Slider(value: doubleBinding({ settings.auraIntensity }, { settings.auraIntensity = $0 }),
                   in: Constants.Aura.intensityRange) { Text("Aura intensity") }
            Slider(value: doubleBinding({ settings.auraThickness }, { settings.auraThickness = $0 }),
                   in: Constants.Aura.thicknessRange) { Text("Aura thickness") }
            Toggle("Reduce motion",
                   isOn: boolBinding({ settings.reduceMotion }, { settings.reduceMotion = $0 }))
            Toggle("Darken screen on start",
                   isOn: boolBinding({ settings.darkenScreenOnStart }, { settings.darkenScreenOnStart = $0 }))
            Toggle("Cinematic countdown",
                   isOn: boolBinding({ settings.cinematicCountdownEnabled }, { settings.cinematicCountdownEnabled = $0 }))
        }.padding()
    }

    private var dataTab: some View {
        Form {
            Text("Session history is stored locally on this Mac.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Button("Clear local data", role: .destructive, action: onClearData)
        }.padding()
    }
}

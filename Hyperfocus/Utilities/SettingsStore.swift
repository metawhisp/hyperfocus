// SettingsStore.swift — typed UserDefaults access for every canon §8 key, with locked defaults.

import Foundation

final class SettingsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: General

    var launchAtLogin: Bool {
        get { bool(Constants.SettingsKeys.launchAtLogin, Constants.Defaults.launchAtLogin) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.launchAtLogin) }
    }

    var showOrbOnLaunch: Bool {
        get { bool(Constants.SettingsKeys.showOrbOnLaunch, Constants.Defaults.showOrbOnLaunch) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.showOrbOnLaunch) }
    }

    var orbSize: Double {
        get { double(Constants.SettingsKeys.orbSize, Constants.Defaults.orbSize) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.orbSize) }
    }

    var orbOpacity: Double {
        get { double(Constants.SettingsKeys.orbOpacity, Constants.Defaults.orbOpacity) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.orbOpacity) }
    }

    /// JSON `{x,y}` string; nil means the default bottom-right position (owned by OrbPositionStore).
    var orbPosition: String? {
        get { defaults.string(forKey: Constants.SettingsKeys.orbPosition) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.orbPosition) }
    }

    // MARK: Focus

    var defaultDurationMinutes: Int {
        get { int(Constants.SettingsKeys.defaultDurationMinutes, Constants.Defaults.defaultDurationMinutes) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.defaultDurationMinutes) }
    }

    var defaultIntensity: Intensity {
        get {
            let raw = defaults.string(forKey: Constants.SettingsKeys.defaultIntensity) ?? ""
            return Intensity(rawValue: raw) ?? Constants.Defaults.defaultIntensity
        }
        set { defaults.set(newValue.rawValue, forKey: Constants.SettingsKeys.defaultIntensity) }
    }

    var warningThresholdSeconds: Int {
        get { int(Constants.SettingsKeys.warningThresholdSeconds, Constants.Defaults.warningThresholdSeconds) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.warningThresholdSeconds) }
    }

    var awayThresholdSeconds: Int {
        get { int(Constants.SettingsKeys.awayThresholdSeconds, Constants.Defaults.awayThresholdSeconds) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.awayThresholdSeconds) }
    }

    var recoverySeconds: Int {
        get { int(Constants.SettingsKeys.recoverySeconds, Constants.Defaults.recoverySeconds) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.recoverySeconds) }
    }

    var allowSessionsWithoutCamera: Bool {
        get { bool(Constants.SettingsKeys.allowSessionsWithoutCamera, Constants.Defaults.allowSessionsWithoutCamera) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.allowSessionsWithoutCamera) }
    }

    // MARK: Camera

    var useCameraForPresence: Bool {
        get { bool(Constants.SettingsKeys.useCameraForPresence, Constants.Defaults.useCameraForPresence) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.useCameraForPresence) }
    }

    var useScreenAnalysis: Bool {
        get { bool(Constants.SettingsKeys.useScreenAnalysis, Constants.Defaults.useScreenAnalysis) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.useScreenAnalysis) }
    }

    /// Strict = react to looking away (attention cone); off = presence only (multi-monitor).
    var strictAttention: Bool {
        get { bool(Constants.SettingsKeys.strictAttention, Constants.Defaults.strictAttention) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.strictAttention) }
    }

    // MARK: Sound

    var voicePromptsEnabled: Bool {
        get { bool(Constants.SettingsKeys.voicePromptsEnabled, Constants.Defaults.voicePromptsEnabled) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.voicePromptsEnabled) }
    }

    var alarmEnabled: Bool {
        get { bool(Constants.SettingsKeys.alarmEnabled, Constants.Defaults.alarmEnabled) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.alarmEnabled) }
    }

    var soundVolume: Double {
        get { double(Constants.SettingsKeys.soundVolume, Constants.Defaults.soundVolume) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.soundVolume) }
    }

    var voiceStyle: VoiceStyle {
        get {
            let raw = defaults.string(forKey: Constants.SettingsKeys.voiceStyle) ?? ""
            return VoiceStyle(rawValue: raw) ?? Constants.Defaults.voiceStyle
        }
        set { defaults.set(newValue.rawValue, forKey: Constants.SettingsKeys.voiceStyle) }
    }

    var voicePersona: VoicePersona {
        get {
            let raw = defaults.string(forKey: Constants.SettingsKeys.voicePersona) ?? ""
            return VoicePersona(rawValue: raw) ?? Constants.Defaults.voicePersona
        }
        set { defaults.set(newValue.rawValue, forKey: Constants.SettingsKeys.voicePersona) }
    }

    var focusSoundEnabled: Bool {
        get { bool(Constants.SettingsKeys.focusSoundEnabled, Constants.Defaults.focusSoundEnabled) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.focusSoundEnabled) }
    }

    var focusSoundMode: FocusSoundMode {
        get {
            let raw = defaults.string(forKey: Constants.SettingsKeys.focusSoundMode) ?? ""
            return FocusSoundMode(rawValue: raw) ?? Constants.Defaults.focusSoundMode
        }
        set { defaults.set(newValue.rawValue, forKey: Constants.SettingsKeys.focusSoundMode) }
    }

    var focusSoundVolume: Double {
        get { double(Constants.SettingsKeys.focusSoundVolume, Constants.Defaults.focusSoundVolume) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.focusSoundVolume) }
    }

    /// Filename of the user's custom focus audio inside App Support/Hyperfocus/FocusSound.
    var focusSoundFile: String? {
        get { defaults.string(forKey: Constants.SettingsKeys.focusSoundFile) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.focusSoundFile) }
    }

    // MARK: Visual

    var auraIntensity: Double {
        get { double(Constants.SettingsKeys.auraIntensity, Constants.Defaults.auraIntensity) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.auraIntensity) }
    }

    var auraThickness: Double {
        get { double(Constants.SettingsKeys.auraThickness, Constants.Defaults.auraThickness) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.auraThickness) }
    }

    var reduceMotion: Bool {
        get { bool(Constants.SettingsKeys.reduceMotion, Constants.Defaults.reduceMotion) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.reduceMotion) }
    }

    var darkenScreenOnStart: Bool {
        get { bool(Constants.SettingsKeys.darkenScreenOnStart, Constants.Defaults.darkenScreenOnStart) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.darkenScreenOnStart) }
    }

    var cinematicCountdownEnabled: Bool {
        get { bool(Constants.SettingsKeys.cinematicCountdownEnabled, Constants.Defaults.cinematicCountdownEnabled) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.cinematicCountdownEnabled) }
    }

    // MARK: Internal

    var onboardingCompleted: Bool {
        get { bool(Constants.SettingsKeys.onboardingCompleted, Constants.Defaults.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Constants.SettingsKeys.onboardingCompleted) }
    }

    // MARK: Private helpers

    private func bool(_ key: String, _ fallback: Bool) -> Bool {
        defaults.object(forKey: key) as? Bool ?? fallback
    }

    private func int(_ key: String, _ fallback: Int) -> Int {
        defaults.object(forKey: key) as? Int ?? fallback
    }

    private func double(_ key: String, _ fallback: Double) -> Double {
        defaults.object(forKey: key) as? Double ?? fallback
    }
}

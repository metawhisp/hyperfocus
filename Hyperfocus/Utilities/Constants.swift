// Constants.swift — every locked literal from canon §3, §6, §8, §9: thresholds, defaults, keys, copy strings, tuning values.

import Foundation

enum Constants {

    // MARK: Timing thresholds (canon §4; defaults, user-tunable)

    enum Timing {
        static let warningThresholdSeconds = 7      // face missing this long → warning
        static let awayThresholdSeconds = 15        // face missing this long → away
        static let recoverySeconds = 3              // face continuously present this long in recovering → active
        static let sleepGapSeconds: Double = 5      // tick delta above this counts as paused time
        static let maxTickDecrementSeconds: Double = 1  // per-tick decrement clamp
    }

    // MARK: UserDefaults keys (canon §8; string literal = property name, prefix "hf.")

    enum SettingsKeys {
        static let launchAtLogin = "hf.launchAtLogin"
        static let showOrbOnLaunch = "hf.showOrbOnLaunch"
        static let orbSize = "hf.orbSize"
        static let orbOpacity = "hf.orbOpacity"
        static let orbPosition = "hf.orbPosition"
        static let defaultDurationMinutes = "hf.defaultDurationMinutes"
        static let defaultIntensity = "hf.defaultIntensity"
        static let warningThresholdSeconds = "hf.warningThresholdSeconds"
        static let awayThresholdSeconds = "hf.awayThresholdSeconds"
        static let recoverySeconds = "hf.recoverySeconds"
        static let allowSessionsWithoutCamera = "hf.allowSessionsWithoutCamera"
        static let useCameraForPresence = "hf.useCameraForPresence"
        static let useScreenAnalysis = "hf.useScreenAnalysis"
        static let voicePromptsEnabled = "hf.voicePromptsEnabled"
        static let alarmEnabled = "hf.alarmEnabled"
        static let soundVolume = "hf.soundVolume"
        static let voiceStyle = "hf.voiceStyle"
        static let voicePersona = "hf.voicePersona"
        static let focusSoundEnabled = "hf.focusSoundEnabled"
        static let focusSoundMode = "hf.focusSoundMode"
        static let focusSoundVolume = "hf.focusSoundVolume"
        static let focusSoundFile = "hf.focusSoundFile"      // filename inside App Support/Hyperfocus/FocusSound
        static let auraIntensity = "hf.auraIntensity"
        static let auraThickness = "hf.auraThickness"
        static let reduceMotion = "hf.reduceMotion"
        static let darkenScreenOnStart = "hf.darkenScreenOnStart"
        static let cinematicCountdownEnabled = "hf.cinematicCountdownEnabled"
        static let onboardingCompleted = "hf.onboardingCompleted"
    }

    // MARK: Settings defaults (canon §8)

    enum Defaults {
        static let launchAtLogin = false
        static let showOrbOnLaunch = true
        static let orbSize: Double = 22             // range 18–24
        static let orbOpacity: Double = 0.9         // range 0.4–1.0
        static let defaultDurationMinutes = 25
        static let defaultIntensity: Intensity = .cinematic
        static let warningThresholdSeconds = Timing.warningThresholdSeconds
        static let awayThresholdSeconds = Timing.awayThresholdSeconds
        static let recoverySeconds = Timing.recoverySeconds
        static let allowSessionsWithoutCamera = true
        static let useCameraForPresence = true
        static let useScreenAnalysis = true       // effective only when Screen Recording is granted
        static let voicePromptsEnabled = true
        static let alarmEnabled = true
        static let soundVolume: Double = 0.5
        static let voiceStyle: VoiceStyle = .calm
        static let voicePersona: VoicePersona = .caspian
        static let focusSoundEnabled = true
        static let focusSoundMode: FocusSoundMode = .pad     // our generated ambient pad (canon #29)
        static let focusSoundVolume: Double = 0.4            // slider is pre-scaled: 1.0 ≈ whisper ceiling
        static let auraIntensity: Double = 0.7      // range 0.2–1.0
        static let auraThickness: Double = 1.0      // range 0.5–1.5, multiplier on Aura.baseThickness
        static let reduceMotion = false
        static let darkenScreenOnStart = true
        static let cinematicCountdownEnabled = true
        static let onboardingCompleted = false
    }

    // MARK: Orb geometry (canon §3)

    enum Orb {
        static let sizeRange: ClosedRange<Double> = 18...24
        static let opacityRange: ClosedRange<Double> = 0.4...1.0
        static let edgeSnapDistance: Double = 32    // pt from screen edge that triggers snapping
        static let edgeMargin: Double = 8           // pt margin after snapping
        static let clickMaxMovement: Double = 4     // pt; mouseUp under this = click, not drag
        static let clickMaxDuration: Double = 0.3   // s;  mouseUp under this = click, not drag
        static let longPressSeconds: Double = 0.5   // hold in place this long → quick-start chips
    }

    // MARK: Aura geometry (canon §3)

    enum Aura {
        static let baseThickness: Double = 120      // pt strip per edge, before auraThickness multiplier
        static let edgeMaxOpacity: Double = 0.55    // gradient start opacity, multiplied by auraIntensity
        static let intensityRange: ClosedRange<Double> = 0.2...1.0
        static let thicknessRange: ClosedRange<Double> = 0.5...1.5
    }

    // MARK: Camera (canon §1, §6)

    enum Camera {
        static let queueLabel = "com.hyperfocus.camera"
        static let detectionInterval: Double = 0.5  // Vision face detection at most every 0.5 s (2 Hz)
        static let captureWidth = 640
        static let captureHeight = 480
    }

    // MARK: Voice parameters per style (canon §6)

    enum Voice {
        static func rate(for style: VoiceStyle) -> Float {
            switch style {
            case .calm: return 0.45
            case .strict: return 0.52
            case .cinematic: return 0.42
            }
        }
        static func pitchMultiplier(for style: VoiceStyle) -> Float {
            switch style {
            case .calm: return 1.0
            case .strict: return 0.95
            case .cinematic: return 0.85
            }
        }
    }

    // MARK: Alarm (canon §6)

    enum Alarm {
        static let fadeInSeconds: Double = 0.8
        static let brownNoiseIntegration: Float = 0.02   // brown += (white - brown * 0.02)
        static let brownNoiseGain: Float = 3.5           // sample = brown * 3.5 * volume
    }

    // MARK: Intensity → behavior mapping (canon §8)

    enum IntensityTuning {
        static func auraIntensityMultiplier(for intensity: Intensity) -> Double {
            switch intensity {
            case .calm: return 0.8
            case .strict: return 1.0
            case .cinematic: return 1.2
            }
        }
        static func alarmVolumeMultiplier(for intensity: Intensity) -> Double {
            switch intensity {
            case .calm: return 0.7
            case .strict: return 1.1
            case .cinematic: return 1.0
            }
        }
        static func voiceStyle(for intensity: Intensity) -> VoiceStyle {
            switch intensity {
            case .calm: return .calm
            case .strict: return .strict
            case .cinematic: return .cinematic
            }
        }
    }

    // MARK: Screen analysis (canon §13 #23) — local distraction detection via on-screen text

    enum Screen {
        static let analysisInterval: Double = 12      // seconds between local screen captures during a session
        static let captureScale = 2                   // downscale factor for the analyzed frame
        static let distractionKeywords = [
            "youtube", "tiktok", "instagram", "twitter", " x.com", "reddit", "netflix",
            "twitch", "facebook", "for you", "shorts", "tweet", "9gag", "pornhub",
        ]
        /// If the MISSION itself mentions the matched service (in EN or RU), it's the work,
        /// not a distraction — "смонтировать ютуб ролик" must never be nudged about YouTube.
        static let keywordAliases: [String: [String]] = [
            "youtube": ["ютуб", "youtube", "видео"], "shorts": ["ютуб", "youtube", "шортс"],
            "tiktok": ["тикток", "tiktok"], "instagram": ["инстаграм", "инст", "reels", "рилс"],
            "twitter": ["твиттер", "твит", "twitter"], " x.com": ["твиттер", "x.com"],
            "tweet": ["твиттер", "твит", "twitter"], "reddit": ["реддит", "reddit"],
            "netflix": ["нетфликс", "netflix"], "twitch": ["твич", "twitch", "стрим"],
            "facebook": ["фейсбук", "facebook"], "for you": ["тикток", "tiktok"],
        ]
    }

    // MARK: Storage (canon §7)

    enum Storage {
        static let directoryName = "Hyperfocus"
        static let fileName = "sessions.json"
    }

    // MARK: Copy canon (canon §9 — exact strings, do not paraphrase)

    enum Copy {

        // Voice lines (spoken)
        static func voiceLine(_ line: VoiceLine) -> String {
            switch line {
            case .countdown: return "Enter Hyperfocus Mode. Three. Two. One. Focus."
            case .away: return "Session paused. Return to Hyperfocus or exit."
            case .restored: return "Focus restored."
            case .complete: return "Mission complete."
            }
        }

        // Start card
        static let startCardTitle = "Prepare Hyperfocus"
        static let startCardSubtitle = "One task. One session."
        static let missionPlaceholder = "What are you doing in this session?"
        static let successPlaceholder = "This session is successful if…"
        static let startPrimaryCTA = "Enter Hyperfocus"
        static let startSecondaryCTA = "Cancel"
        static let durationPresetsMinutes = [5, 15, 25, 45]
        static let customDurationLabel = "Custom"
        static let customDurationRangeMinutes: ClosedRange<Int> = 1...180

        // Countdown overlay text sequence
        static let countdownSequence = ["ENTER HYPERFOCUS MODE", "3", "2", "1", "FOCUS"]

        // Away card
        static let awayCardTitle = "Session paused"
        static let awayCardText = "Return to Hyperfocus or exit the session."
        static let awayReturnButton = "Return"
        static let awayExitButton = "Exit Session"

        // Recovery countdown
        static let recoverySequence = ["3", "2", "1", "Back to focus"]

        // Completion card
        static let completionTitle = "Mission complete"
        static let completionQuestion = "Did you complete the mission?"
        static let completionDoneButton = "Done"
        static let completionPartialButton = "Partial"
        static let completionNotDoneButton = "Not done"
        static let nextActionPlaceholder = "Next action"

        // HUD camera status strings
        static let hudStatusPresent = "Present"
        static let hudStatusLooking = "Looking for you"
        static let hudStatusAway = "Away"
        static let hudStatusCameraOff = "Camera off"
        static let hudStatusPermissionNeeded = "Permission needed"

        // Privacy copy (onboarding + Settings → Camera)
        static let privacyCopy = "Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally on your Mac. Hyperfocus does not record, save, or upload camera footage."

        // Onboarding (5 screens, exact per BRIEF)
        static let onboarding1Title = "Hyperfocus for Mac"
        static let onboarding1Text = "A cinematic focus mode for one task at a time."
        static let onboarding2Title = "Enter focus mode"
        static let onboarding2Text = "Click the orb, choose a mission, start the countdown."
        static let onboarding3Title = "Presence check"
        static let onboarding3Text = "Hyperfocus can use your camera to pause the timer when you leave."
        static let onboarding4Title = "Private by default"
        static let onboarding4Text = "Camera frames are processed locally. No recording. No upload."
        static let onboarding5CTA = "Start using Hyperfocus"

        // Orb quick actions (right-click / long-press menu)
        static let orbActionPause = "Pause"
        static let orbActionExitSession = "Exit Session"
        static let orbActionHide = "Hide for 10 minutes"
        static let orbActionSettings = "Settings…"
    }
}

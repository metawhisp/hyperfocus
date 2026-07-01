# 00-CANON — Hyperfocus: Single Source of Truth

> **Precedence:** on any detail conflict between documents, THIS file wins.
> On product-intent conflict, `specs/BRIEF.md` wins.
> Every other doc in `specs/` must use the exact names, values, and strings defined here.
> If an implementing agent needs to deviate, it must update this file first (one commit),
> then the dependent code — never silently.

Status: designed 2026-07-02. Verified against Xcode 26.2 / Swift 6.2.3 / macOS 26.5 on the target machine.

---

## 1. Technology decisions (locked)

| Decision | Value | Why |
|---|---|---|
| Language | Swift, **Swift 5 language mode** (`SWIFT_VERSION: 5.0`, `SWIFT_STRICT_CONCURRENCY: minimal`) | Avoids strict-concurrency friction in AppKit-heavy overlay code; MVP pragmatism |
| UI | SwiftUI views hosted in AppKit windows (`NSHostingView`/`NSHostingController`) | Overlays need window-level control SwiftUI alone can't provide |
| Deployment target | **macOS 15.0** | Machine runs 26.5; 15.0 keeps APIs stable and well-known to all agents |
| Glass styling | Baseline: `.ultraThinMaterial` / `NSVisualEffectView` + custom gradients. Optional enhancement behind `if #available(macOS 26.0, *)`: `.glassEffect()` | Liquid Glass look without betting the MVP on macOS-26-only APIs |
| Project generation | **XcodeGen** (`project.yml` is the source of truth; `.xcodeproj` is generated, git-ignored) | Agents can regenerate the project deterministically; no `.xcodeproj` merge conflicts |
| Dependencies | **None.** Apple frameworks only (SwiftUI, AppKit, AVFoundation, Vision, Combine, ServiceManagement) | Zero supply-chain surface, zero setup |
| Session storage | JSON file via `Codable` at `FileManager.applicationSupportDirectory/Hyperfocus/sessions.json` (on disk under App Sandbox: see §7 container-path note) | Simplest testable persistence; SwiftData is overkill for one array |
| Settings storage | `UserDefaults` via `@AppStorage` / `SettingsStore` | Standard |
| App style | `LSUIElement = true` (no Dock icon) + `MenuBarExtra` for Settings/History/Quit | The orb is the primary UI; Dock icon adds noise |
| Voice | `AVSpeechSynthesizer` | NSSpeechSynthesizer is deprecated |
| Alarm | Programmatic **brown noise** via `AVAudioEngine` + `AVAudioSourceNode` (no audio assets) | No binary assets in repo; volume controllable; loops trivially |
| Camera | `AVCaptureSession` at 640×480, `VNDetectFaceRectanglesRequest` throttled to **2 Hz** | Enough for presence; low CPU/power |
| Tests | XCTest, unit target `HyperfocusTests` | State machine, timer accounting, stores are pure and fully testable |

Build & run commands (must stay true):

```bash
brew install xcodegen        # once
xcodegen generate            # regenerates Hyperfocus.xcodeproj from project.yml
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus -configuration Debug build
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus test
open Hyperfocus.xcodeproj    # or run from Xcode
```

---

## 2. Module map (locked file structure)

```
project.yml                          # XcodeGen manifest (source of truth for the project)
Hyperfocus/
  App/
    HyperfocusApp.swift              # @main, MenuBarExtra, AppDelegate adaptor
    AppDelegate.swift                # window bootstrap, screen-change observation
    AppState.swift                   # ObservableObject root: owns coordinator + services
    SessionCoordinator.swift         # applies SessionEffect side effects to services/windows
  Session/
    SessionState.swift               # enum SessionState (see §4)
    SessionEvent.swift               # enum SessionEvent (see §5)
    SessionEffect.swift              # enum SessionEffect (see §5)
    SessionReducer.swift             # PURE function: (inout SessionContext, SessionEvent) -> [SessionEffect]
    SessionContext.swift             # mutable session runtime data (counters, config)
    SessionConfig.swift              # mission, duration, intensity, cameraEnabled
    SessionModel.swift               # persisted Session struct (see §7)
    SessionTimer.swift               # 1 Hz tick source, monotonic-clock deltas
    SessionStore.swift               # JSON persistence of [Session]
  Orb/
    FocusOrbWindowController.swift   # KeyablePanel, drag, edge snapping
    FocusOrbView.swift               # SwiftUI orb visuals per OrbVisualState
    OrbPositionStore.swift           # persists position, clamps to visible bounds
  Aura/
    AuraWindowController.swift       # owns 4 edge windows on main screen
    AuraFrameView.swift              # gradient glow per edge
    AuraState.swift                  # enum AuraState: hidden, green, yellow, red, dimmed, flashThenHide
  UI/
    StartSessionView.swift           # "Prepare Hyperfocus" card
    CountdownOverlayView.swift       # fullscreen 3-2-1 overlay
    ActiveHUDView.swift              # mission / time / status HUD
    AwayModeView.swift               # "Session paused" card
    CompletionView.swift             # "Mission complete" card
    SettingsView.swift               # settings window (see §8)
    OnboardingView.swift             # 5-screen first-launch flow
    HistoryView.swift                # simple session list
    GlassCard.swift                  # shared glass-card container style
  Camera/
    PresenceDetecting.swift          # protocol (see §6)
    CameraPresenceService.swift      # AVFoundation + Vision implementation
    CameraPermissionService.swift    # authorization status + request
    SimulatedPresenceService.swift   # debug implementation (menu-driven)
  Audio/
    VoicePrompting.swift             # protocol
    VoicePromptService.swift         # AVSpeechSynthesizer implementation
    AlarmPlaying.swift               # protocol
    AlarmService.swift               # AVAudioEngine brown-noise loop
  Utilities/
    KeyablePanel.swift               # NSPanel subclass, canBecomeKey = true
    OverlayWindow.swift              # borderless click-through window factory
    ScreenManager.swift              # main-screen frame, visible bounds, change events
    SettingsStore.swift              # typed UserDefaults access (keys in §8)
    Constants.swift                  # all literals from this canon
HyperfocusTests/
  SessionReducerTests.swift
  SessionTimerTests.swift
  SessionStoreTests.swift
  OrbPositionStoreTests.swift
```

Rules:
- Do NOT rename these files/types. Do NOT merge modules "for convenience".
- UI never talks to services directly; everything flows `event -> reducer -> effects -> coordinator`.
- All UI mutation on main thread. Camera/Vision work on `com.hyperfocus.camera` serial queue; presence events delivered to main.

---

## 3. Window inventory (AppKit specifics, locked)

| Window | Class | styleMask | level | ignoresMouseEvents | collectionBehavior |
|---|---|---|---|---|---|
| Focus Orb | `KeyablePanel` | `[.borderless, .nonactivatingPanel]` | `.statusBar` | false | `[.canJoinAllSpaces, .fullScreenAuxiliary]` |
| Start card | `KeyablePanel` (positioned next to orb) | `[.borderless, .nonactivatingPanel]` | `.statusBar` | false | same |
| Countdown | borderless `NSWindow`, main screen frame | `[.borderless]` | `.screenSaver` | false | same |
| Aura ×4 | borderless `NSWindow` per edge | `[.borderless]` | `.statusBar` | **true** | `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` |
| Away card | `KeyablePanel`, centered | `[.borderless, .nonactivatingPanel]` | `.screenSaver` | false | same |
| Completion card | `KeyablePanel`, centered | `[.borderless, .nonactivatingPanel]` | `.floating` | false | same |
| Settings / History / Onboarding | standard `NSWindow` (SwiftUI `Window` scenes OK) | default | `.normal` | false | default |

Known AppKit gotchas the implementation MUST handle (documented here so agents don't rediscover them):
1. Borderless panels can't take keyboard focus by default → `KeyablePanel` overrides `canBecomeKey` to return `true`. Mission text field will not work otherwise.
2. All overlay windows: `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false` (except cards, which want `hasShadow = true`).
3. Aura windows must never steal focus: never call `makeKey`; order with `orderFrontRegardless()`.
4. Orb drag: implement in the view via `NSEvent` mouse tracking moving the panel's frame (not `isMovableByWindowBackground`, which breaks click detection). Click = mouseUp with < 4 pt total movement and < 0.3 s duration; otherwise it was a drag.
5. Edge snap: after drag ends, if orb center is within **32 pt** of a screen edge, animate frame to **8 pt** margin from that edge.
6. On `NSApplication.didChangeScreenParametersNotification`: clamp orb into `NSScreen.main.visibleFrame`, rebuild aura windows.
7. MVP is single-screen: all overlays target `NSScreen.main` at the moment the session starts.

Aura geometry: each edge window is a strip **120 pt** thick (before `auraThickness` multiplier), spanning the full edge, drawn as a linear gradient from `edgeColor.opacity(0.55 × auraIntensity)` at the screen edge to `.clear` inward. Corners overlap; that is acceptable.

---

## 4. State machine (locked)

```swift
enum SessionState: String, Codable {
    case idle, preparing, countdown, active, warning, away,
         recovering, manualPaused, completed, exited
}
```

Timing constants (defaults; user-tunable in Settings, see §8):

| Constant | Default | Meaning |
|---|---|---|
| `warningThresholdSeconds` | 7 | face missing this long → warning |
| `awayThresholdSeconds` | 15 | face missing this long → away |
| `recoverySeconds` | 3 | face continuously present this long in recovering → active |

### Transition table

Events are defined in §5. `ctx` = `SessionContext`.

| # | From | Event / condition | To | Key effects |
|---|---|---|---|---|
| T1 | idle | `.orbClicked` | preparing | `.showStartCard` |
| T2 | preparing | `.cancelPreparing` | idle | `.hideStartCard` |
| T3 | preparing | `.enterHyperfocus(config)` (mission non-empty) | countdown | `.hideStartCard`, `.showCountdown`, `.playVoice(.countdown)`, `.startCameraWarmup` |
| T4 | countdown | `.countdownCompleted` | active | `.dismissCountdown`, `.setAura(.green)`, `.startTimer`, `.startPresenceDetection` |
| T5 | countdown | `.userExited` | idle | `.dismissCountdown`, `.stopCamera` (abort, nothing saved) |
| T6 | active | `.tick` while `ctx.faceMissingSeconds ≥ warningThreshold` | warning | `.setAura(.yellow)` |
| T7 | warning | `.facePresenceChanged(true)` | active | `.setAura(.green)` (no recovery delay; counter resets) |
| T8 | warning | `.tick` while `ctx.faceMissingSeconds ≥ awayThreshold` | away | `.setAura(.red)`, `.pauseTimer`, `.startAlarm`, `.playVoice(.away)`, `.showAwayCard`; `ctx.breakCount += 1`; streak resets |
| T9 | active | direct away condition (e.g. debug `.simulateAway`) | away | same as T8 |
| T10 | away | `.facePresenceChanged(true)` | recovering | `.showRecoveryCountdown` (alarm keeps playing) |
| T11 | recovering | `.facePresenceChanged(false)` | away | `.hideRecoveryCountdown` (flagged addition — brief omits it, required for correctness) |
| T12 | recovering | `.tick` while face present and `ctx.recoveryElapsed ≥ recoverySeconds` | active | `.stopAlarm`, `.hideAwayCard`, `.hideRecoveryCountdown`, `.setAura(.green)`, `.resumeTimer`, `.playVoice(.restored)` |
| T13 | active | `.userPaused` | manualPaused | `.pauseTimer`, `.setAura(.dimmed)` |
| T14 | manualPaused | `.userResumed` | active | `.resumeTimer`, `.setAura(.green)` |
| T15 | active / warning | `.tick` when `remainingFocusTime == 0` | completed | `.stopTimer`, `.stopCamera`, `.stopAlarm`, `.setAura(.flashThenHide)`, `.playVoice(.complete)`, `.showCompletion` |
| T16 | active / warning / away / recovering / manualPaused | `.userExited` | exited | `.stopTimer`, `.stopCamera`, `.stopAlarm`, `.setAura(.hidden)`, `.hideAwayCard`, `.saveSession(status: .exited)` |
| T17 | completed | `.resultSaved(status, nextAction)` | idle | `.saveSession(status)`, `.hideCompletion`, `.orbFlash` |
| T18 | exited | (immediate, emitted by reducer) | idle | — |

Flagged additions relative to the brief (T2, T5, T11, T16 extended sources): the brief's transition list omits cancel/abort paths and losing the face during recovery. These are required for a correct product and are canon.

### Timer accounting rules (locked)

- Tick source: `SessionTimer` fires 1 Hz on the main run loop; each tick carries `deltaSeconds` computed from a **monotonic clock** (`ContinuousClock` / `CACurrentMediaTime()`), not wall clock.
- Per-tick decrement is **clamped to 1 second**. If `delta > 5 s` (machine slept / app stalled), the excess is added to `pausedSeconds`, not to focus time. (Flagged decision.)
- `SessionContext` runtime counters (`remainingFocusTime`, `activeFocusSeconds`, `pausedSeconds`, `currentStreakSeconds`, `longestStreakSeconds`, `faceMissingSeconds`, `recoveryElapsed`) are `Double` (fractional seconds), accruing `min(deltaSeconds, 1.0)` per tick; persisted `Session` fields stay `Int` per §7, rounded to nearest at save time. (Flagged decision.)
- `remainingFocusTime` decreases only in `active` and `warning`.
- `activeFocusSeconds` increases only in `active` and `warning` (the same seconds that decrement remaining).
- `pausedSeconds` increases in `away`, `recovering`, `manualPaused`.
- `currentStreakSeconds` increases with `activeFocusSeconds`; resets to 0 on entering `away` or `manualPaused` (not on `warning`).
- `longestStreakSeconds = max(longestStreakSeconds, currentStreakSeconds)`, updated every tick.
- `breakCount` increments once per entry into `away`. Manual pause does NOT increment `breakCount`. (Flagged decision.)
- No-camera session: presence events never fire; only manual pause and exit change the running state.

### Presence debouncing

`faceMissingSeconds` accumulates on ticks while the last raw presence value is `false`; resets to 0 whenever a `facePresent` raw event arrives. Raw camera flicker shorter than one detection interval (0.5 s) is therefore absorbed for free. No additional debounce layer.

### Camera degradation mid-session (locked)

When `.cameraStateChanged(.unavailable / .disabled / .notAuthorized)` arrives during a running session, presence can no longer be verified and the session degrades to no-camera semantics, per state:

- **active** — stay in `active`; presence-driven transitions disabled; timer keeps running; HUD shows `Camera off`.
- **warning** — return to `active` applying T7's effect list; `faceMissingSeconds` resets.
- **away / recovering** — treat exactly as `facePresenceChanged(true)`: away → recovering (T10), then after `recoverySeconds` → active (T12 — alarm stops, timer resumes).

Rationale: a session must never stay stuck with a looping alarm after the camera disappears. This subsection is the single source of truth; 02 §6/§11 and 03 §5 must match it.

---

## 5. Events and effects (locked enums)

```swift
enum SessionEvent {
    case orbClicked
    case cancelPreparing
    case enterHyperfocus(SessionConfig)
    case countdownCompleted
    case tick(deltaSeconds: Double)
    case facePresenceChanged(Bool)     // raw, from PresenceDetecting
    case cameraStateChanged(CameraState)
    case userPaused
    case userResumed
    case userExited
    case resultSaved(CompletionStatus, nextAction: String?)
}

enum SessionEffect: Equatable {
    case showStartCard, hideStartCard
    case showCountdown, dismissCountdown
    case setAura(AuraState)
    case startTimer, pauseTimer, resumeTimer, stopTimer
    case startCameraWarmup, startPresenceDetection, stopCamera
    case startAlarm, stopAlarm
    case playVoice(VoiceLine)
    case showAwayCard, hideAwayCard
    case showRecoveryCountdown, hideRecoveryCountdown
    case showCompletion, hideCompletion
    case saveSession(CompletionStatus)
    case orbFlash
}

enum VoiceLine { case countdown, away, restored, complete }

enum CameraState: Equatable {
    case notAuthorized, unavailable, disabled
    case facePresent, faceMissing
}

enum AuraState { case hidden, green, yellow, red, dimmed, flashThenHide }
```

`SessionReducer` is a pure, synchronous, main-thread-only function:

```swift
struct SessionReducer {
    static func reduce(_ ctx: inout SessionContext, _ event: SessionEvent) -> [SessionEffect]
}
```

It never touches AppKit, AVFoundation, or the file system. **This is the primary TDD surface** — every transition in §4 gets a unit test before implementation.

`SessionCoordinator` (main thread) executes effects against concrete services and window controllers. It is thin and mostly untested glue.

---

## 6. Service contracts (locked protocols)

```swift
protocol PresenceDetecting: AnyObject {
    var onEvent: ((PresenceEvent) -> Void)? { get set }  // delivered on main thread
    func startWarmup()          // pre-roll camera during countdown
    func startDetection()
    func stop()
}

enum PresenceEvent: Equatable {
    case facePresent
    case faceMissing
    case cameraState(CameraState)
}

protocol VoicePrompting: AnyObject {
    func speak(_ line: VoiceLine, style: VoiceStyle)
    func stopSpeaking()
}

protocol AlarmPlaying: AnyObject {
    func start(volume: Float)
    func stop()
    var isPlaying: Bool { get }
}
```

- `CameraPresenceService: PresenceDetecting` — real implementation. AVCaptureSession preset `.vga640x480`, frames on `com.hyperfocus.camera` queue, `VNDetectFaceRectanglesRequest` at most every 0.5 s (drop frames in between), emits an event only when the detected value CHANGES (plus one initial value).
- `SimulatedPresenceService: PresenceDetecting` — debug implementation driven by menu commands (§10).
- Privacy invariants (enforced in code review): no `AVCaptureMovieFileOutput`, no `AVAssetWriter`, no writing of `CVPixelBuffer`/`CGImage` anywhere, no network calls in the entire app. Camera session torn down (`stopRunning`, inputs/outputs removed) on `stopCamera`.

Voice parameters per style:

| VoiceStyle | rate | pitchMultiplier | notes |
|---|---|---|---|
| `.calm` | 0.45 | 1.0 | default AVSpeechSynthesisVoice en-US |
| `.strict` | 0.52 | 0.95 | slightly faster, flatter |
| `.cinematic` | 0.42 | 0.85 | slower, lower — "sci-fi" |

Alarm: brown noise generated in `AVAudioSourceNode` render block (`brown += (white - brown * 0.02); sample = brown * 3.5 × volume`, clamp to [-1, 1]), through `AVAudioEngine.mainMixerNode`. Fade in over 0.8 s. Loops until `stop()`.

---

## 7. Data model (locked)

```swift
struct Session: Codable, Identifiable, Equatable {
    let id: UUID
    var mission: String
    var successCondition: String?
    var plannedDurationSeconds: Int
    var activeFocusSeconds: Int
    var pausedSeconds: Int
    var breakCount: Int
    var longestStreakSeconds: Int
    var completionStatus: CompletionStatus
    var startedAt: Date
    var endedAt: Date?
    var intensity: Intensity
    var cameraEnabled: Bool
    var nextAction: String?          // flagged addition: completion screen has this field
}

enum CompletionStatus: String, Codable { case done, partial, notDone, exited }
enum Intensity: String, Codable, CaseIterable { case calm, strict, cinematic }
```

`SessionStore`: loads/saves `[Session]` as pretty-printed JSON at
`FileManager.applicationSupportDirectory/Hyperfocus/sessions.json` (create directory if missing);
exposes `append(_:)`, `all()`, `clear()`. Injectable directory URL for tests.

Note: under App Sandbox, `FileManager.applicationSupportDirectory` resolves on disk to `~/Library/Containers/com.hyperfocus.app/Data/Library/Application Support/Hyperfocus/sessions.json` — manual-verification instructions must use the container path.

---

## 8. Settings (locked keys and defaults)

UserDefaults keys — string literal = property name, prefix `hf.`:

| Key | Type | Default | Section |
|---|---|---|---|
| `hf.launchAtLogin` | Bool | false | General (via `SMAppService.mainApp`) |
| `hf.showOrbOnLaunch` | Bool | true | General |
| `hf.orbSize` | Double | 22 (range 18–24) | General |
| `hf.orbOpacity` | Double | 0.9 (range 0.4–1.0) | General |
| `hf.orbPosition` | String (JSON `{x,y}`) | bottom-right, 8 pt margin | (hidden; "Reset orb position" button) |
| `hf.defaultDurationMinutes` | Int | 25 | Focus |
| `hf.defaultIntensity` | String (Intensity) | `cinematic` | Focus (flagged decision: matches product identity) |
| `hf.warningThresholdSeconds` | Int | 7 | Focus |
| `hf.awayThresholdSeconds` | Int | 15 | Focus |
| `hf.recoverySeconds` | Int | 3 | Focus |
| `hf.allowSessionsWithoutCamera` | Bool | true | Focus |
| `hf.useCameraForPresence` | Bool | true | Camera |
| `hf.voicePromptsEnabled` | Bool | true | Sound |
| `hf.alarmEnabled` | Bool | true | Sound |
| `hf.soundVolume` | Double | 0.5 | Sound |
| `hf.voiceStyle` | String (VoiceStyle) | `calm` | Sound |
| `hf.auraIntensity` | Double | 0.7 (0.2–1.0) | Visual |
| `hf.auraThickness` | Double | 1.0 (0.5–1.5, multiplier on 120 pt) | Visual |
| `hf.reduceMotion` | Bool | false | Visual |
| `hf.darkenScreenOnStart` | Bool | true | Visual |
| `hf.cinematicCountdownEnabled` | Bool | true | Visual |
| `hf.onboardingCompleted` | Bool | false | (internal) |

`hf.cinematicCountdownEnabled == false` selects the standard (non-cinematic) countdown variant — the countdown overlay is never skipped, and the `countdown` state and `.countdownCompleted` timing are unchanged.

Intensity → behavior mapping:

| Aspect | calm | strict | cinematic |
|---|---|---|---|
| auraIntensity multiplier | 0.8× | 1.0× | 1.2× |
| alarm volume multiplier | 0.7× | 1.1× | 1.0× |
| voice style used in session | calm | strict | cinematic |
| countdown | standard fade | standard, faster | extra glow, slower scale, longer fades |

`Constants.swift` holds every literal above.

---

## 9. Copy canon (exact strings — do not paraphrase)

Voice lines (spoken):
- countdown: `Enter Hyperfocus Mode. Three. Two. One. Focus.`
- away: `Session paused. Return to Hyperfocus or exit.`
- restored: `Focus restored.`
- complete: `Mission complete.`

Start card: title `Prepare Hyperfocus`, subtitle `One task. One session.`,
mission placeholder `What are you doing in this session?`,
success placeholder `This session is successful if…`,
primary CTA `Enter Hyperfocus`, secondary `Cancel`.
Duration presets: `5`, `15`, `25`, `45` minutes + `Custom` (1–180, stepper or text).

Countdown overlay text sequence: `ENTER HYPERFOCUS MODE` → `3` → `2` → `1` → `FOCUS`.

Away card: title `Session paused`, text `Return to Hyperfocus or exit the session.`,
buttons `Return` (enabled only while face visible; triggers nothing extra — recovery is automatic, the button exists as an affordance and simply confirms/focuses recovery) and `Exit Session`.

Recovery countdown: `3` → `2` → `1` → `Back to focus`.

Completion card: title `Mission complete`, fields Mission / Focus time / Paused time / Breaks / Longest streak,
question `Did you complete the mission?`, buttons `Done` / `Partial` / `Not done`,
optional field placeholder `Next action`.

HUD camera status strings: `Present`, `Looking for you`, `Away`, `Camera off`, `Permission needed`.

Privacy copy (onboarding + Settings → Camera):
`Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally on your Mac. Hyperfocus does not record, save, or upload camera footage.`

Onboarding: 5 screens exactly as in BRIEF (`Hyperfocus for Mac`, `Enter focus mode`, `Presence check`, `Private by default`, CTA `Start using Hyperfocus`).

Tone rules: never use shaming language (`You failed`, `Try harder`, …) anywhere, including code comments shown to users, notifications, or logs surfaced in UI.

Orb quick actions (right-click / long-press menu): `Pause` (active only — disabled/hidden in every other state, per T13), `Exit Session` (session running), `Hide for 10 minutes`, `Settings…`.

---

## 10. Debug simulation (required in MVP)

Menu bar extra contains a `Debug` submenu (compiled only in `DEBUG` builds):
- `Simulate: Face Present` → `SimulatedPresenceService` emits `.facePresent`
- `Simulate: Face Missing` → emits `.faceMissing`
- `Simulate: Jump to Away` → emits `.faceMissing` and fast-forwards `faceMissingSeconds` to `awayThresholdSeconds`
- `Simulate: Return` → emits `.facePresent`
- `Use Simulated Camera` (toggle) → swaps `PresenceDetecting` implementation for the next session

This must exercise the full flow (green → yellow → red → alarm → recovery → completion) with no camera.

---

## 11. Info.plist / entitlements (locked)

- `NSCameraUsageDescription`: `Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally and never recorded or uploaded.`
- `LSUIElement`: `true`
- Entitlements: App Sandbox **enabled**, `com.apple.security.device.camera = true`. No network entitlements.
- Bundle id: `com.hyperfocus.app`. Signing: automatic, local development team ("Sign to Run Locally" acceptable).

---

## 12. Explicitly out of scope (from BRIEF)

Team rooms, social sessions, cloud sync, subscriptions, payments, AI coach, website blocking, iPhone camera mode, advanced analytics, App Store flow. Also out: multi-screen aura (main screen only), localization (English UI only), haptics.

---

## 13. Flagged decisions log

Deviations/refinements vs. BRIEF, all intentional:
1. T2/T5/T11 transitions added (cancel preparing, abort countdown, face lost during recovery).
2. `userExited` allowed from `warning`/`recovering`/`manualPaused`, not only `active`/`away`.
3. Sleep gap > 5 s counts as paused time, capped 1 s/tick decrement.
4. Manual pause does not increment `breakCount`; only `away` does.
5. `nextAction` added to the persisted `Session` model (the brief defines the field on the completion screen but omits it from the model).
6. Default intensity `cinematic` (product identity); default voice style `calm` (non-intrusive).
7. Storage = JSON file, not SwiftData/SQLite (simplicity; brief allowed any).
8. `Return` button in the away card is an affordance; actual resume is automatic after 3 s of presence, per BRIEF's recovery rule.
9. XcodeGen instead of a committed `.xcodeproj`.
10. Swift 5 language mode + minimal strict concurrency.
11. Camera loss mid-session behavior locked in §4 "Camera degradation mid-session": per-state degradation (active stays, warning → active via T7's effects, away/recovering treated as `facePresenceChanged(true)`); a session never stays stuck with a looping alarm.
12. `hf.cinematicCountdownEnabled == false` means the standard (non-cinematic) countdown variant; the overlay is never skipped; `countdown` state and `.countdownCompleted` timing unchanged.
13. `SessionContext` runtime counters are `Double` (fractional seconds), accruing `min(deltaSeconds, 1.0)` per tick; persisted `Session` fields stay `Int` (§7), rounded to nearest at save time.
14. Unit-test names: the catalog in `specs/06-testing.md` §4 is authoritative; test names in specs/03/04/05 are informal references — on any mismatch, 06 §4 wins.
15. Sandboxed storage path: programmatic truth is `FileManager.applicationSupportDirectory`; on disk under App Sandbox that is `~/Library/Containers/com.hyperfocus.app/Data/Library/Application Support/Hyperfocus/sessions.json` — manual-verification instructions use the container path.
16. Intensity modes do NOT vary prompt frequency/wording in MVP — the away line is spoken once, same copy for all styles.

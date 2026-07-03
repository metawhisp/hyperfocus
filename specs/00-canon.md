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
17. Default orb position is **top-right** (8 pt margin), not bottom-right — updated per product feedback (§8 default `hf.orbPosition`, `OrbPositionStore.defaultPosition`). Orb window footprint is 60 pt (glow room); the whole window is clamped on-screen so it is never edge-clipped.
18. Orb interaction: **short click → start** (opens the Prepare card with the mission field auto-focused); **long-press (≥ 0.5 s) → Settings**; drag moves it; right-click → quick actions. No configuration is required to start (ADHD-friendly, low friction).
19. Voice prompts are **pre-recorded cinematic clips** (Higgsfield `seed_audio`, voice "Caspian", deep male), bundled as `Hyperfocus/Resources/Voice/{countdown,away,restored,complete}.wav` and played via `AVAudioPlayer`; `AVSpeechSynthesizer` is a fallback only. Supersedes the "voice via AVSpeech / no binary assets" note for voice (the alarm stays procedural).
20. Aura is intentionally **faint and living**: peak alpha ≈ `0.55 × auraIntensity × 0.6`, with a slow breathe + per-edge phase-offset shimmer (TimelineView), static under reduce-motion. Left/right edge strips are inset by the strip thickness so corners no longer double-draw/overlap.
21. Voice is user-selectable between personas **Caspian** and **Gideon** (setting `hf.voicePersona`, default caspian). Each persona has its own four bundled WAVs (`<persona>_<line>.wav`). The old `hf.voiceStyle` (calm/strict/cinematic) now only tunes the AVSpeech fallback and is no longer surfaced in Settings.
22. Timer/countdown use a bundled **segmented display font** (DSEG, SIL OFL, `Resources/Fonts/DSEG{7,14}Classic-Bold.ttf`, license included): DSEG7 for the numeric HUD clock and completion stat values, DSEG14 for the 3·2·1·FOCUS countdown frames. Registered at launch via CoreText; falls back to the system font if registration fails. The long "ENTER HYPERFOCUS MODE" intro stays in the rounded font for readability.
23. Onboarding requests permissions up front: a **Camera** step (`AVCaptureDevice.requestAccess`) and a **Screen analysis** step (`CGRequestScreenCaptureAccess`, TCC Screen Recording — no entitlement). Both are optional ("Not now") and consent-based. Onboarding grows to 6 screens (intro, enter focus, camera, screen analysis, private-by-default, CTA).
24. **Screen analysis feature** (`ScreenAnalysisService`, `Hyperfocus/Screen/`): during a session, every `Constants.Screen.analysisInterval` (12 s) it captures the main display via ScreenCaptureKit, runs Vision text recognition **in memory**, and matches against `Constants.Screen.distractionKeywords`; a hit shows a gentle non-shaming `NudgeView` ("Still on it? Back to: <mission>", auto-dismiss 6 s). Gated by `hf.useScreenAnalysis` (default true) AND `CGPreflightScreenCaptureAccess()`. **Privacy: frames are analyzed in memory and discarded — never written, saved, or uploaded; no network.** Only the matched term leaves the service. Starts on `.startTimer`, stops on `.stopTimer`. (`DebugSnapshots` uses `tiffRepresentation` for DEBUG-only UI PNGs — it never touches camera/screen frames.)
25. **Orb v4 — ring ⇄ particles morph** (user-approved from live previews; supersedes v3 ring). One entity, two forms: **off/idle = calm red ring** (240 overlapping dots forming a solid circle, ember halo); **on = the ring dissolves into a BRIGHT rotating green particle sphere** (the same 240 angle-sorted dots fly to Fibonacci-lattice positions; eased 0.9 s morph; inner bloom + wide halo, brightness ×2.2 — an ADHD-grade beacon, deliberately loud). State mapping (`OrbMorphStyle`): idle/exited p=0 red ×1.3; preparing/countdown/active p=1 green ×2.2 (pulse while preparing); warning amber ×2.4 pulsing; away/recovering alarm-red ×2.6 pulsing; manualPaused dim green ×1.1; completed green ×2.6. Hover: ×1.08 scale + ×1.18 brightness. Reduce-motion: instant state jumps, no rotation. Renderer `RingToParticlesOrb` lives in FocusOrbView.swift and also powers the DEBUG live gallery. Clickability is unchanged (circular 3% layer backing on the container + acceptsFirstMouse, HF_SELFTEST-guarded). State language: **idle = deep-red calm "sleep"** (slow rotation), preparing/countdown = **green** (the click morph), active = steady green, warning = amber, away/recovering = bright fast red (distinct from idle red), manualPaused = dim green. **Hover** scales ×1.14 and speeds rotation (alive feedback; `AppState.orbHovered` via NSTrackingArea). **Interaction:** short click toggles — idle → `.orbClicked` (green + Prepare card), preparing → `.cancelPreparing` (red sleep), any running state → `.userExited` (red sleep); **long-press (≥ `Constants.Orb.longPressSeconds` = 0.5 s)** shows quick-start chips (the 3 most recent distinct durations, fallback 25/15/45) fading in left/right/below the orb — drag onto a chip and release to start immediately (mission = last session's mission, else "Focus"; the showStartCard/hideStartCard pair is suppressed so no card flash). Settings now lives in the right-click menu + menu bar. New file: `Hyperfocus/Orb/QuickStartView.swift`. Refinements after adversarial review: click = stationary release (< 4 pt) before the long-press threshold — the 0.3 s duration cutoff was dropped (no 0.3–0.5 s dead zone), and a declined long-press (session running) falls through to a normal click; the orb window moves only once a drag is committed (≥ 4 pt); chip/card placement and orb clamping use the orb's own screen (`currentVisibleBounds`), not `NSScreen.main`; chips pick free slots (left/right/below/below₂/above) so they never cover the orb or each other; reduce-motion renders the target color immediately (no frozen mid-morph); rapid re-clicks morph from the currently displayed color.
26. **Onboarding v2 — activation-first** (supersedes the BRIEF's five text screens; §9 onboarding copy no longer ships). Five interactive steps: (1) meet the orb — a LIVE morphing orb the user must physically CLICK to continue (teaches the core gesture by doing); (2) type the first mission + pick 5/15/25 min (collected for real use, default 15 — small first win); (3) camera permission with value-first copy (presence pauses the timer; local-only, never recorded/uploaded); (4) screen-analysis permission (distraction radar; local-only); (5) recap of the three gestures (click / hold / right-click) + primary CTA that closes onboarding AND immediately starts the first session via quickStart(mission:minutes:) — the user exits onboarding INSIDE a running session (ADHD activation). 'I'll start later' fallback. Rationale: the old onboarding was descriptive marketing with no actionable outcome.
27. **Session-exit confirmation + up-front permissions + window-chrome cleanup.** (a) A click on the orb (or the HUD Exit) during a RUNNING session never exits directly: the aura flashes red and an `ExitConfirmView` card asks "Exit Hyperfocus?" (Stay focused / Exit session); countdown abort stays direct (T5, nothing saved); away/recovering ignore orb clicks (their own card is up). The confirm card is dismissed automatically if the session ends or away fires. (b) Camera permission is NEVER requested at session start — collected in onboarding, and if still missing at launch a `PermissionNudgeView` explains the camera is required for the full product (prompt if undetermined, else a System Settings link). Unauthorized sessions silently degrade to plain timers. (c) Green active/preparing orb brightness raised ×2.2 → ×2.7 (glow was barely visible). (d) Card panels use `hasShadow = false` (the system shadow drew a rectangular hairline box around transparent windows) and quick-start chips lost their white strokeBorder — cards carry their own SwiftUI shadows.
28. **Aura v2 — uniform perimeter frame** (user-picked design A1 "ровная рамка"; supersedes #20's 4-strip construction, which left corner gaps). ONE full-screen click-through overlay window; the aura is a single closed `Rectangle().strokeBorder` (lineWidth 12 × auraThickness, blur 18 × auraThickness) — even glow along the entire perimeter, corners included, bleeding inward. Near-steady breathe (0.92 + 0.08·sin 0.7t), static under reduce-motion, render loop paused while hidden. Stroke alpha = min(1, edgeOpacity × 3) since the band concentrates what the old wide gradient spread out. AuraWindowController now owns one window instead of four; `AuraEdge` removed. ALSO: camera presence upgraded to ATTENTION detection — VNDetectFaceRectanglesRequestRevision3 head pose; present = face in frame AND |yaw| ≤ 0.6 rad AND |pitch| ≤ 0.55 rad, so looking away / at a phone escalates warning→away like leaving does (HFCAM debug logs for live tuning).
29. **FLIGHT DECK production rollout** (user-approved from live previews; supersedes the NEON VOID variant A for shipped screens; specs/07 v2). (a) Design system: FD tokens + FDCard/FDInset/MatrixTimer/FDProgress/PixelIcon/FDBadge/FDPrimaryButton/FDGhostButton/FDChip/FDCloseButton in DesignSystem.swift; Doto (OFL) dot-matrix font for hero text/timers with a custom two-dot separator; countdown numerals switched to Doto. (b) Screens restyled: READY? start card (mission + in-field magic wand, 5/15/25/45/CUSTOM, one full-width CTA, no Cancel/success-condition/intensity), centered HUD (countdown + mission + X + burning progress: % from 10%, lime→amber@70%→red@85%; no camera pill), pulsing STOP confirm (skull + STOPPING COUNTS AS NOT DONE), PAUSED away card, HYPERFOCUS COMPLETE (actual focus time hero, NEW ACHIEVEMENT banner, badge row, mission question retained), FD quick-start chips/nudge/history. (c) PAUSE REMOVED from all UI (quick menu offers Stop Hyperfocus… → confirm); reducer T13/T14 retained as dead paths for now; History shows exited as "Not done". (d) Achievements engine: AchievementsStore (achievements.json; 16 launch rules: firsts/quality/volume/rhythm/day-streaks/time-of-day; burned counter for early stops — never celebrated); evaluated on .showCompletion; unlocks passed to CompletionView(unlocks:onResult:) with nextAction dropped (nil). (e) Magic wand: ScreenContextService suggests "Continue: <frontmost window title>" locally (falls back to app name without the Screen Recording grant). (f) FocusSoundService: procedural session soundscape — brown (default, speaker-safe) or binaural 200/240 Hz (40 Hz beat, headphones note in Settings); keys hf.focusSoundEnabled/Mode/Volume (true/brown/0.35); starts with .startTimer, stops on .pauseTimer (away — alarm owns audio), resumes on .resumeTimer, stops on .stopTimer; no efficacy claims in copy. Onboarding FLIGHT DECK implementation pending (storyboard approved as preview).
30. **Generated Ambient Pad + gradual swell + matrix countdown intro** (user-directed: "наш звук, не из видео; звонко, не шум" / intro "сделать как у нас текст в приложении" — picked gallery variant A). (a) `PadSynth.swift` is the production focus sound and single source of truth (the HF_SOUND_PREVIEW gallery auditions the same `PadRenderer`): A/E chord (110/164.81/220L/260R/329.63 — keeps the reference track's 40 Hz interaural pair), 3-voice unison detune ±0.27%, octave partial 0.22, per-note amplitude LFOs at unrelated 0.013–0.041 Hz, Freeverb-lite reverb (combs 1116/1188/1277/1356, allpasses 556/441, fb .86, damp .30, +23-sample stereo spread), 55/45 dry/wet; masterScale .185 = raw RMS .18 (verified by full-render simulation, level-matched to the other candidates). `.pad` is the new `FocusSoundMode` default. No noise component anywhere. (b) Every focus-sound mode — pad, brown, binaural, custom file — swells in over 12 s on a SQUARED perceptual curve (`gain = target × fade²`; AVAudioPlayer's linear fade replaced by a 10 Hz stepped quadratic ramp): the music must appear gradually, never as a jump cut. PadRenderer is allocated off the realtime render thread on every path. (c) Countdown intro frame "ENTER HYPERFOCUS MODE" now uses the same dot-matrix treatment as the 3·2·1·FOCUS frames (`FD.matrix(116)`, auto-shrink to width) — no more rounded system font; picked from the HF_COUNTDOWN_PREVIEW gallery (variant A over B stack / C boot / D chip).
31. **All generated soundscapes ship as selectable FocusSoundModes + LOCK IN v2** (user: "все остальные звуки окей... надо, чтоб пользователь мог в настройках выбрать звук"). (a) `FocusScapes.swift` is production now: DroneBank/DroneRenderer (humTide, humSweep, droneChorus, droneFifth, warmHybrid — RMS-matched sine stacks with slow drift) and LockInBank/LockInRenderer; the HF_SOUND_PREVIEW gallery is a thin shell over these exact renderers. `FocusSoundMode` = pad · humTide · humSweep · droneChorus · droneFifth · warmHybrid · lockIn · brown · binaural · custom; Settings picker lists them all; default stays `.pad`; raw strings persist (old prefs decode unchanged). (b) LOCK IN v2 hiss fix (user: "слишком шумный"): faithful-render simulation exposed that the v1 bed sat at raw RMS ≈ 1.10 — ~+16 dB over the .18 row target (the "≈ RMS .10" comment was wrong); v2 darkens the LP corners (~420/900 Hz) and sets bedScale .032 → bed ≈ .09, total ≈ .187, hiss band (>800 Hz) −28 dB; toneScale .28→.30. (c) LOCK IN production sections follow the SESSION clock (stabilize <60 s, s1 <20 min, s2 <40 min, s3 hold): FocusSoundService keeps a `sessionAnchor` (beginSession on .startTimer, endSession on .stopTimer) and offsets render time by it, so away stop/start cycles resume the arc instead of replaying the intro — defect found and confirmed by the adversarial review workflow before commit.
32. **Progress bar design G (FLOW+RULER) shipped + session-start stinger + one green** (user-picked from the HF_HUD_PREVIEW gallery). (a) `FDProgress` = design G: diagonal stripes (FDFlowStripes Canvas) crawl through the fill, ruler ticks at 10%…90% (tall at 50%) glimmer one-at-a-time in the dark zone, % label from 30%, head dot removed, min fill 14pt; 30 fps TimelineView paused under reduce-motion (`animated:` param from ActiveHUDView). Tick offset is +width/20 — the review workflow caught the original −width/20 putting ticks at 0–80% with the midpoint at 40%. (b) One green: session elements (orb #29EB8C = Palette.green, aura, progress fill, mini-timer glow) share the orb green; FLIGHT DECK lime stays for controls (buttons/chips) pending the user's global-accent decision. (c) HUD panel is user-draggable (isMovableByWindowBackground). (d) Card windows carry transparent shadow margins (60/44/84; chips 18/12/26) so FDCard blur fades to 0 instead of clipping into dirty edges; all placement math targets the visible card rect. (e) Session start: bundled 2 s cinematic stinger (Resources/Sounds/session-start.mp3, user-provided royalty-free) plays at soundVolume×0.5 the moment the countdown opens, faded out on Esc. (f) Exit confirmation flares the red aura (boost 1.9× width/blur/alpha, 0.35 s) until answered. (g) READY? card: CUSTOM duration swaps IN PLACE of the chips row in a fixed 38pt slot (if/else layers — an opacity-hidden TextField would stay in the key-view loop and swallow Tab; caught by review + live repro).
33. **HUD collapse-to-orb** (demo-approved in HF_MINI_PREVIEW: "Да, теперь мне нравится нормально" + orb-green pill). Double-click anywhere on the timer card → it fades out (0.22 s) and a compact MiniTimerPill (matrix mm:ss in a dark capsule, orb-green glow — UI/MiniTimerView.swift, shared with the demo) docks 8 pt under the orb, following it via a windowNumber-matched NSWindow.didMoveNotification observer (flips above the orb when there is no room below). Click the digits → the card fades back. Lifecycle hardening from the adversarial review (both confirmed by live repro): an `isCollapsing` in-flight flag plus a completion-time currency check (`hudPanel === hud`, session still running) prevent (a) a stale pill docking after .stopTimer lands mid-fade and (b) a rapid second double-click orphaning a duplicate pill + leaking its observer; expandHUD never resurrects a HUD outside a running session; .stopTimer tears the pill down.
34. **Quick-start chips = gallery design E "GHOST NUMBERS"** (user-picked from HF_CHIPS_PREVIEW). No containers: FD.matrix(26) digits + tiny MIN caption + lime underline tick, materializing from blur (0.35 s, 0.12 s stagger); drag-over turns the digit lime, scales 1.15 and doubles the glow. Production adaptations: a dark text shadow keeps digits readable over light desktops (gallery cells were dark); CardMargins.chip grew to 44/36/44 for the r18 glow, so drag hit-testing now targets the VISIBLE digits (+12 pt tolerance ring) via chipHitRect — fat glow margins would otherwise overlap neighboring chip windows and steal the highlight. Kills the old gray-pill truncation bug ("15…").
35. **Distraction Radar v2 — context-aware** (user: "должна быть нейронка дешёвая, которая анализирует контекст"; a YouTube mission must never be nudged about YouTube). Three layers: (a) keyword prefilter every 12 s (unchanged, cheap); (b) mission-aware suppression — the matched term is checked against the mission text incl. RU aliases (ютуб/тикток/инстаграм/рилс/твич/…, Constants.Screen.keywordAliases); (c) on-device context judge (DistractionJudge, Screen/): when Apple Intelligence is available (macOS 26+, canImport(FoundationModels) + SystemLanguageModel .available) the built-in LLM gets the mission + a ≤1200-char OCR excerpt and answers YES/NO on drifting — nudge only on YES; HFJUDGE NSLog for tuning. Unavailable/error → sides with the keyword hit (old behavior); deployment target stays macOS 15. The 60 s radar cooldown is claimed BEFORE judging, so the model runs ≤1/min. Verified on this machine: FoundationModels present, status appleIntelligenceNotEnabled → judge dormant until the user flips Apple Intelligence on.

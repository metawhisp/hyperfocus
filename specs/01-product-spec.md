# 01 — Product / UI / UX Specification

> Derives from `specs/BRIEF.md` (product intent) and `specs/00-canon.md` (technical truth).
> On any detail conflict, `00-canon.md` wins; on product-intent conflict, `BRIEF.md` wins.
> All identifiers, thresholds, copy strings, settings keys, and file paths below are the canon's exact values — do not paraphrase or rename.

## 0. Conventions

- **MUST** = acceptance-blocking requirement. **SHOULD** = expected unless a documented reason exists. **MAY** = optional.
- Values marked **[spec-defined]** are fixed by this document because canon/BRIEF leave them open (animation durations, hex colors, control ranges). They are normative for the MVP; changing them does not require a canon update, but changing any canon value does.
- "Session state" refers to `SessionState` (canon §4). "Aura state" refers to `AuraState` (canon §5). All UI reacts to reducer effects only (canon §2 rules); no view may drive services directly.
- Time strings: durations render as `mm:ss` when < 1 hour, `h:mm:ss` otherwise, zero-padded (`18:42`, `1:05:09`) **[spec-defined]**.

---

## 1. Focus Orb

Always-on-top floating glass dot; the app's primary entry point. Window per canon §3 (`KeyablePanel`, `.statusBar` level, `[.canJoinAllSpaces, .fullScreenAuxiliary]`).

### 1.1 Visual states

`FocusOrbView` renders one of the following `OrbVisualState` values, mapped from `SessionState` **[mapping spec-defined where BRIEF is silent]**:

| OrbVisualState | SessionState(s) | Appearance |
|---|---|---|
| `idle` | idle | Translucent glass circle, no colored core, faint white rim highlight |
| `ready` | preparing, countdown, recovering | Soft green pulse: core opacity 0.5→0.8, scale 1.00→1.08, 2.0 s cycle, ease-in-out **[spec-defined]** |
| `active` | active | Steady green core (#30D158) at 0.85 opacity, no pulse |
| `warning` | warning | Amber pulse (#FFD60A): 1.2 s cycle, same amplitude as `ready` **[spec-defined]** |
| `away` | away | Steady red core (#FF453A) plus slow 1.6 s pulse **[spec-defined]** |
| `paused` | manualPaused | Dimmed gray core (#98989D at 0.6 opacity), no pulse **[spec-defined]** |
| `completed` | completed → (on `.orbFlash`) | Single green flash: core to 1.0 opacity over 0.25 s, fade back to `idle` over 0.9 s **[spec-defined]** |

- With `hf.reduceMotion == true`, all pulses MUST be replaced by static color at the pulse's mid opacity; the completed flash MUST be a 0.4 s opacity-only crossfade.
- Orb diameter MUST equal `hf.orbSize` (18–24, default 22). Orb overall opacity MUST equal `hf.orbOpacity` (0.4–1.0, default 0.9). Both apply live when changed in Settings.

### 1.2 Drag vs click (canon §3 gotcha 4)

- Dragging MUST be implemented via `NSEvent` mouse tracking that moves the panel frame — NOT `isMovableByWindowBackground`.
- A mouse-up MUST be treated as a **click** iff total movement < 4 pt AND duration < 0.3 s; otherwise it is a **drag**.
- Click in `idle` MUST dispatch `.orbClicked` (→ preparing, `.showStartCard`). Click during an active/warning session SHOULD toggle HUD visibility (see §5) **[spec-defined]**; click in `preparing` MUST do nothing (card already open).

### 1.3 Edge snapping and persistence (canon §3 gotcha 5–6)

- After a drag ends, if the orb center is within **32 pt** of any screen edge, the panel MUST animate to an **8 pt** margin from that edge (0.25 s ease-out **[spec-defined]**).
- Position MUST persist via `OrbPositionStore` to `hf.orbPosition` (JSON `{x,y}`); default bottom-right at 8 pt margin.
- On `NSApplication.didChangeScreenParametersNotification`, the orb MUST be clamped into `NSScreen.main.visibleFrame`.
- Restored positions outside the current visible frame MUST be clamped on launch.

### 1.4 Quick-actions menu

Right-click (or long-press ≥ 0.5 s **[spec-defined]**) MUST show a context menu with exactly (canon §9):

| Item | Enabled when | Action |
|---|---|---|
| `Pause` | session in active ONLY (canon T13; disabled/hidden in warning and every other state) | dispatch `.userPaused` |
| `Exit Session` | session in active/warning/away/recovering/manualPaused | dispatch `.userExited` |
| `Hide for 10 minutes` | always | see below |
| `Settings…` | always | open Settings window |

When paused, the first item SHOULD read `Resume` and dispatch `.userResumed` **[spec-defined]**.

**Hide for 10 minutes:** the orb window (and its anchored HUD) MUST be ordered out for 600 s, then reappear at the saved position showing the visual state of the current session state. A running session MUST continue unaffected (timer, aura, camera, away card all keep working). The menu bar extra MUST show a `Show Focus Orb` item while hidden (§11) that restores the orb early and cancels the 10-minute hide timer (never the session timer) **[spec-defined]**.

---

## 2. Start Session card — "Prepare Hyperfocus"

Glass card (`StartSessionView` in a `KeyablePanel`, canon §3) opened by `.showStartCard`, closed by `.hideStartCard`.

### 2.1 Content (copy per canon §9 — exact)

- Title: `Prepare Hyperfocus`. Subtitle: `One task. One session.`
- **Mission** — single-line text field, placeholder `What are you doing in this session?`. Required. Field MUST have keyboard focus when the card opens (this is why `KeyablePanel.canBecomeKey == true` exists).
- **Success condition** — single-line text field, placeholder `This session is successful if…`. Optional.
- **Time** — segmented presets `5` / `15` / `25` / `45` minutes + `Custom`. Selecting `Custom` reveals a stepper or numeric text field accepting **1–180** minutes; out-of-range input MUST be clamped to 1–180. Default selection reflects `hf.defaultDurationMinutes` (preset if it matches 5/15/25/45, else Custom).
- **Intensity** — segmented selector `Calm` / `Strict` / `Cinematic`, default from `hf.defaultIntensity` (default `cinematic`).
- Primary CTA: `Enter Hyperfocus`. Secondary: `Cancel`.

### 2.2 Validation and behavior

- `Enter Hyperfocus` MUST be disabled while `mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`. There is no error banner; the disabled state is the validation **[spec-defined]**.
- Activating the CTA MUST dispatch `.enterHyperfocus(SessionConfig)` with trimmed mission, optional trimmed success condition (nil if empty), duration in seconds, intensity, and `cameraEnabled` derived from `hf.useCameraForPresence` and camera availability.
- `Cancel` MUST dispatch `.cancelPreparing` (→ idle).

### 2.3 Keyboard

- `Esc` MUST behave exactly like `Cancel`.
- `Cmd+Return` MUST behave exactly like `Enter Hyperfocus` (no-op while invalid).
- Plain `Return` in the Mission field SHOULD move focus to Success condition **[spec-defined]**.

### 2.4 Positioning

- The card MUST appear adjacent to the orb with a 12 pt gap **[spec-defined]**, on whichever side keeps the card fully inside `NSScreen.main.visibleFrame` (prefer: toward screen center).
- Card size ≈ 320 × 300 pt **[spec-defined]**; not resizable. Clicking outside the card MUST NOT dismiss it (explicit Cancel/Esc only) **[spec-defined]**.

---

## 3. Countdown overlay

Fullscreen borderless window at `.screenSaver` level covering `NSScreen.main` (canon §3). Shown by `.showCountdown`, removed by `.dismissCountdown`.

### 3.1 Sequence and timing (standard variant) **[timings spec-defined]**

Text sequence (canon §9): `ENTER HYPERFOCUS MODE` → `3` → `2` → `1` → `FOCUS`.

| t (s) | Event |
|---|---|
| 0.0–0.5 | Background scrim fades in to black at 65% opacity (25% if `hf.darkenScreenOnStart == false`) |
| 0.3 | `ENTER HYPERFOCUS MODE` fades in over 0.4 s with scale 0.96→1.00 and a soft glow bloom |
| 0.3–2.0 | Title holds, then fades out over 0.3 s |
| 2.0–3.0 | `3` — fade in 0.15 s, scale 1.00→1.06 across the second, fade out 0.15 s |
| 3.0–4.0 | `2` — same treatment |
| 4.0–5.0 | `1` — same treatment |
| 5.0–5.8 | `FOCUS` — fade in 0.2 s with stronger glow, holds |
| 5.8–6.4 | Overlay fades out over 0.6 s; `.countdownCompleted` is dispatched, aura appears underneath |

- Voice: `.playVoice(.countdown)` fires at t = 0 with the exact line `Enter Hyperfocus Mode. Three. Two. One. Focus.` Digit display cadence is fixed at 1 s; the app MUST NOT gate visuals on speech callbacks (speech is fire-and-forget; approximate sync via the timings above is acceptable).
- Cinematic variant (used when `hf.cinematicCountdownEnabled == true` AND session intensity is `cinematic`, per canon §8 mapping): title hold extended to 2.4 s, digit scale 1.00→1.10, glow radius doubled, final fade 1.0 s **[spec-defined]**. Strict intensity uses the standard variant with digit fades shortened to 0.1 s.
- `hf.cinematicCountdownEnabled == false` means the STANDARD (non-cinematic) variant is used regardless of session intensity. The overlay is NEVER skipped; the `countdown` state and the `.countdownCompleted` timing are unchanged — the flag selects the cinematic vs standard variant only.
- Reduce-motion variant (`hf.reduceMotion == true`): no scaling, no glow animation; scrim and text use plain opacity crossfades (0.2 s); total sequence duration unchanged.

### 3.2 Abort

- `Esc` during countdown MUST dispatch `.userExited` → T5: overlay dismissed, camera warmup stopped, **nothing saved**, state → idle.
- The overlay MUST swallow all other keyboard/mouse input while visible.

---

## 4. Aura Frame

Four borderless windows, one per edge (top/bottom/left/right), `.statusBar` level, `ignoresMouseEvents = true`, `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]` (canon §3). Main screen only; rebuilt on screen-parameter changes.

### 4.1 Geometry (canon §3, locked)

- Each edge window is a strip **120 pt × `hf.auraThickness`** (multiplier 0.5–1.5, default 1.0) thick, spanning the full edge length. Corners overlap; that is acceptable.
- Each strip draws a linear gradient from `edgeColor.opacity(0.55 × effectiveIntensity)` at the screen edge to `.clear` inward, where `effectiveIntensity = clamp(hf.auraIntensity × intensityModeMultiplier, 0, 1)` (`hf.auraIntensity` default 0.7; mode multipliers per §14).

### 4.2 Colors per `AuraState` **[hex spec-defined]**

| AuraState | edgeColor | Notes |
|---|---|---|
| `hidden` | — | all four windows ordered out |
| `green` | #30D158 | active focus |
| `yellow` | #FFD60A | warning (BRIEF allows yellow/orange; this amber is the canonical pick) |
| `red` | #FF453A | away |
| `dimmed` | #98989D at 0.5 × the computed opacity | manualPaused |
| `flashThenHide` | #30D158 | see §4.3 |

### 4.3 Transitions **[timings spec-defined]**

- green ↔ yellow, green ↔ dimmed: 0.6 s ease-in-out color/opacity crossfade.
- → red: 0.3 s (urgency); red → green (recovery): 0.8 s.
- `flashThenHide` (completion): opacity rises to 0.9 × effectiveIntensity over 0.3 s, holds 0.4 s, fades to hidden over 1.2 s, then windows are ordered out.
- Reduce-motion: state changes are instant color swaps; `flashThenHide` becomes a single 0.5 s linear fade-out with no flash.

### 4.4 Subtlety requirements (testable)

- The gradient MUST reach fully `.clear` within the strip; no color may render further than 120 pt × thickness from the edge.
- Effective edge opacity MUST never exceed 1.0 and SHOULD stay ≤ 0.66 at default settings (0.55 × 0.7 × 1.2 cinematic ≈ 0.46 — verify by computed value, not screenshot).
- Aura windows MUST never become key, never call `makeKey`, and MUST be ordered with `orderFrontRegardless()` (canon §3 gotcha 3). All clicks MUST pass through to underlying apps.
- No animation on the aura may run continuously while state is stable (no breathing/shimmer loops) — static glow only **[spec-defined]**, to keep CPU/GPU idle-low.

---

## 5. Active Session HUD

`ActiveHUDView`, a small glass strip anchored to the orb (same side logic as the start card, 12 pt gap **[spec-defined]**).

### 5.1 Content

| Row | Value | Format |
|---|---|---|
| Mission | `SessionConfig.mission` | truncated to 1 line, middle truncation |
| Time | `remainingFocusTime` | `mm:ss` monospaced digits, updates every tick |
| Camera status | see below | exact strings from canon §9 |
| Session status | derived label | `Focus` (active), `Warning`, `Away`, `Recovering`, `Paused` (manualPaused) **[spec-defined]** |
| Exit | button `Exit Session` | dispatches `.userExited` |

Camera status strings MUST be exactly: `Present`, `Looking for you`, `Away`, `Camera off`, `Permission needed`.
Mapping: `facePresent` → `Present`; `faceMissing` (< away threshold) → `Looking for you`; away state → `Away`; camera disabled/unavailable/no-camera session → `Camera off`; `notAuthorized` → `Permission needed`.

### 5.2 Visibility rules

- In `active`: HUD hidden by default; MUST appear while the pointer hovers the orb (200 ms show delay, 500 ms hide delay after hover ends **[spec-defined]**). Orb click toggles it pinned/unpinned (§1.2).
- In `warning` and `away`: HUD MUST be visible regardless of hover.
- In `manualPaused`: HUD SHOULD stay visible **[spec-defined]**.
- HUD MUST hide when the orb is hidden (§1.4) and in idle/preparing/countdown/completed.
- HUD MUST NOT steal keyboard focus; only its Exit button is clickable.

---

## 6. Away Mode card + recovery countdown

`AwayModeView` in a centered `KeyablePanel` at `.screenSaver` level (canon §3). Shown by `.showAwayCard` on entering away (T8/T9), hidden by `.hideAwayCard`.

### 6.1 Away card (copy per canon §9 — exact)

- Title: `Session paused`. Text: `Return to Hyperfocus or exit the session.`
- Buttons: `Return` and `Exit Session`.
- Alongside the card: aura red, alarm looping, `.playVoice(.away)` speaks `Session paused. Return to Hyperfocus or exit.` once (no repeat loop of the voice line; only the alarm loops).

### 6.2 Return button semantics (canon §9 note — exact behavior)

- `Return` MUST be enabled only while the face is currently visible (last raw presence == present).
- Pressing it triggers **nothing extra**: recovery is automatic per T10–T12. The button exists as an affordance — it confirms/focuses recovery but dispatches no event and MUST NOT skip or shorten the 3 s recovery. When disabled it communicates "come back into frame" by its disabled state.
- `Exit Session` MUST dispatch `.userExited` → T16: stop timer/camera/alarm, aura hidden, card hidden, session saved with `completionStatus = .exited`.

### 6.3 Recovery countdown

- On `.facePresenceChanged(true)` in away → recovering (T10): `.showRecoveryCountdown` displays, inside/above the away card, the sequence `3` → `2` → `1` → `Back to focus`, one step per second, driven by ticks against `recoverySeconds` (default 3). The alarm keeps playing during recovery.
- If the face is lost during recovery (T11): `.hideRecoveryCountdown`, back to away — countdown restarts from `3` on the next return.
- On completion (T12): alarm stops, away card and countdown hide, aura → green, timer resumes, voice speaks `Focus restored.`
- `Back to focus` is displayed for 0.8 s before the card dismisses **[spec-defined]**.
- No-camera sessions never show this card (presence events never fire; canon §4).

---

## 7. Completion card

`CompletionView` in a centered `KeyablePanel` at `.floating` level. Shown by `.showCompletion` (T15), hidden by `.hideCompletion` (T17). Aura performs `flashThenHide`; voice speaks `Mission complete.`

### 7.1 Content (copy per canon §9 — exact)

- Title: `Mission complete`.
- Stats fields, in order: **Mission**, **Focus time**, **Paused time**, **Breaks**, **Longest streak**.
  - Focus time = `activeFocusSeconds`, Paused time = `pausedSeconds`, Longest streak = `longestStreakSeconds` — all `mm:ss` (§0); Breaks = `breakCount` as a plain integer.
- Question: `Did you complete the mission?`
- Buttons: `Done` / `Partial` / `Not done`.
- Optional single-line field with placeholder `Next action`.

### 7.2 Behavior

- Selecting a result button MUST dispatch `.resultSaved(status, nextAction:)` with `.done` / `.partial` / `.notDone` and the trimmed Next action (nil if empty) → session persisted, card closes, orb flashes (`.orbFlash`), state → idle, camera already off (stopped at T15).
- The card MUST NOT be dismissible without choosing a result (no close button, Esc ignored) **[spec-defined]** — the three buttons are the only exits.
- `Esc`/`Cmd+Return` are intentionally inert here to prevent accidental mislabeling **[spec-defined]**.

---

## 8. Settings window

Standard `NSWindow` (SwiftUI `Window`/`Settings` scene), fixed width ≈ 420 pt, tabbed sections **[layout spec-defined]**. Every control binds to the exact `hf.*` key (canon §8); changes apply live.

| Section | Control | Type | Range / values | Key (default) |
|---|---|---|---|---|
| General | Launch at login | toggle (via `SMAppService.mainApp`) | — | `hf.launchAtLogin` (false) |
| General | Show Focus Orb on launch | toggle | — | `hf.showOrbOnLaunch` (true) |
| General | Orb size | slider | 18–24 | `hf.orbSize` (22) |
| General | Orb opacity | slider | 0.4–1.0 | `hf.orbOpacity` (0.9) |
| General | Reset orb position | button | resets `hf.orbPosition` to bottom-right 8 pt margin | — |
| Focus | Default duration | stepper | 1–180 min **[range spec-defined]** | `hf.defaultDurationMinutes` (25) |
| Focus | Default intensity | segmented picker | Calm / Strict / Cinematic | `hf.defaultIntensity` (`cinematic`) |
| Focus | Warning threshold seconds | stepper | 3–30, MUST stay < away threshold **[range spec-defined]** | `hf.warningThresholdSeconds` (7) |
| Focus | Away threshold seconds | stepper | 5–60, MUST stay > warning threshold **[range spec-defined]** | `hf.awayThresholdSeconds` (15) |
| Focus | Return recovery seconds | stepper | 1–10 **[range spec-defined]** | `hf.recoverySeconds` (3) |
| Focus | Allow sessions without camera | toggle | — | `hf.allowSessionsWithoutCamera` (true) |
| Camera | Camera permission status | read-only label + `Open System Settings…` button (deep-links Privacy → Camera) | Authorized / Denied / Not determined | — |
| Camera | Use camera for presence check | toggle | — | `hf.useCameraForPresence` (true) |
| Camera | Privacy explanation | static text | exact privacy copy, §9.4 below | — |
| Sound | Voice prompts | toggle | — | `hf.voicePromptsEnabled` (true) |
| Sound | Alarm sound | toggle | — | `hf.alarmEnabled` (true) |
| Sound | Volume | slider | 0.0–1.0 | `hf.soundVolume` (0.5) |
| Sound | Voice style | picker | Calm / Strict / Cinematic | `hf.voiceStyle` (`calm`) |
| Visual | Aura intensity | slider | 0.2–1.0 | `hf.auraIntensity` (0.7) |
| Visual | Aura thickness | slider | 0.5–1.5 (× 120 pt) | `hf.auraThickness` (1.0) |
| Visual | Reduce motion | toggle | — | `hf.reduceMotion` (false) |
| Visual | Darken screen on start | toggle | — | `hf.darkenScreenOnStart` (true) |
| Visual | Cinematic countdown | toggle | — | `hf.cinematicCountdownEnabled` (true) |
| Data | Session history | button — opens History window (§10) | — | — |
| Data | Clear local data | button with confirmation alert; empties `sessions.json` via `SessionStore.clear()` | — | — |

- Threshold steppers MUST enforce warning < away by clamping the other value when a change would violate the invariant **[spec-defined]**.
- Threshold/recovery changes MUST NOT retroactively alter a session already past a threshold; they apply from the next evaluation tick.
- `hf.voicePromptsEnabled == false` → `.playVoice` effects become no-ops in the audio layer (reducer output unchanged). `hf.alarmEnabled == false` → `.startAlarm` is a no-op. Away card and red aura still appear.

## 9. Onboarding

`OnboardingView`, standard window, shown on first launch while `hf.onboardingCompleted == false`; sets it `true` on finish. 5 screens, paged, back/forward navigation; copy exact per BRIEF/canon §9:

| # | Title | Text / CTA |
|---|---|---|
| 1 | `Hyperfocus for Mac` | `A cinematic focus mode for one task at a time.` |
| 2 | `Enter focus mode` | `Click the orb, choose a mission, start the countdown.` |
| 3 | `Presence check` | `Hyperfocus can use your camera to pause the timer when you leave.` |
| 4 | `Private by default` | `Camera frames are processed locally. No recording. No upload.` |
| 5 | — | CTA button: `Start using Hyperfocus` |

- Screen 4 MUST also display the full privacy copy: `Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally on your Mac. Hyperfocus does not record, save, or upload camera footage.`
- **Camera permission flow placement:** onboarding MUST NOT trigger the system camera permission prompt. The prompt is requested at the first session start with camera enabled (`.startCameraWarmup`, per BRIEF's "check permission at session start"). Onboarding screens 3–4 only explain and set expectations.
- The CTA closes onboarding and shows the orb (respecting `hf.showOrbOnLaunch`).

## 10. Session History

`HistoryView`, standard window opened from the menu bar extra or Settings → Data. Minimal per BRIEF.

- A plain scrollable list of persisted sessions from `SessionStore`, sorted by `startedAt` descending **[spec-defined]**.
- Each row MUST show: Date (`startedAt`, short date + time), Mission (1 line, truncated), Duration (`activeFocusSeconds` per §0), Status (`Done` / `Partial` / `Not done` / `Exited` from `completionStatus`), Breaks (`breakCount`).
- Empty state text: `No sessions yet.` **[spec-defined]**.
- No editing, no deletion of individual rows, no charts (out of scope; canon §12). Clearing happens only via Settings → Data → Clear local data.

## 11. Menu bar extra

`MenuBarExtra` (canon §1: `LSUIElement = true`, no Dock icon). Icon: template-rendered dot/circle glyph (SF Symbol `circle.inset.filled` or equivalent) **[spec-defined]**.

Menu items, top to bottom **[order spec-defined; contents per canon §1 + §10]**:

1. `Show Focus Orb` — present only while the orb is hidden via "Hide for 10 minutes" or `hf.showOrbOnLaunch == false`; restores it immediately.
2. `Settings…` — opens Settings window.
3. `Session History…` — opens History window.
4. `Debug` submenu — **compiled only in `DEBUG` builds** (canon §10), items exactly:
   - `Simulate: Face Present` → `SimulatedPresenceService` emits `.facePresent`
   - `Simulate: Face Missing` → emits `.faceMissing`
   - `Simulate: Jump to Away` → emits `.faceMissing` and fast-forwards `faceMissingSeconds` to `awayThresholdSeconds`
   - `Simulate: Return` → emits `.facePresent`
   - `Use Simulated Camera` (checkmark toggle) → swaps the `PresenceDetecting` implementation for the next session
5. `Quit Hyperfocus` — terminates the app; if a session is running, it MUST first dispatch `.userExited` so the session is saved as `exited` **[spec-defined]**.

The Debug submenu MUST allow exercising the full flow green → yellow → red → alarm → recovery → completion with no physical camera (canon §10).

## 12. Visual design language

Target: expensive macOS, not gaming UI (BRIEF). No neon saturation, no chrome bevels, no gamer HUD framing, no emoji in UI.

### 12.1 Glass card recipe **[spec-defined]** — implemented once in `GlassCard.swift`

- Background: `.ultraThinMaterial` (dark appearance), with optional `if #available(macOS 26.0, *) { .glassEffect() }` enhancement (canon §1).
- Corner radius: 16 pt, continuous corners.
- Stroke: 1 pt, white at 12% opacity.
- Shadow: black at 30% opacity, radius 24, y-offset 8 (cards set `hasShadow = true`; other overlays false, canon §3).
- Content padding: 20 pt. Cards MUST use `GlassCard` — no per-view re-implementations.

### 12.2 Palette **[spec-defined]**

| Token | Hex | Use |
|---|---|---|
| Focus green | #30D158 | active aura, orb core, positive accents |
| Warning amber | #FFD60A | warning aura/orb |
| Away red | #FF453A | away aura/orb, alarm context |
| Dim gray | #98989D | paused states |
| Text primary | white 100% | titles, timer |
| Text secondary | white 60% | subtitles, labels, placeholders |

Defined once in `Constants.swift`. UI chrome otherwise inherits system dark-translucent materials; no custom brand colors beyond this table.

### 12.3 Typography **[spec-defined]**

- System font (SF Pro) everywhere; no bundled fonts.
- Countdown digits/title: system, thin weight, ~96 pt digits / ~34 pt tracking-expanded uppercase title.
- Card titles: 17 pt semibold. Body/labels: 13 pt regular. HUD: 12 pt; all timers use monospaced digits (`.monospacedDigit`).

### 12.4 Motion principles

- Standard durations 0.2–0.6 s, ease-in-out; springs gentle (no overshoot > 5%). Long fades reserved for aura/completion (§4.3).
- Nothing loops while state is stable except orb pulses in `ready`/`warning`/`away`.
- Reduce motion: effective flag = `hf.reduceMotion` OR system `accessibilityDisplayShouldReduceMotion` **[spec-defined]**; when set, every animation in this spec degrades to opacity-only crossfades ≤ 0.5 s (specific variants in §1.1, §3.1, §4.3).

### 12.5 Guardrails (testable)

- Aura MUST NOT obscure content beyond its gradient strip (§4.4); text under the aura MUST remain readable (gradient reaches `.clear`).
- No UI sound except voice lines and alarm. No badges, confetti, streaks-gamification, or achievement popups.
- All copy in UI comes from canon §9 / this spec — no ad-hoc strings.

## 13. Tone rules (BRIEF — enforced everywhere, incl. notifications and UI-surfaced logs)

Allowed phrases: `Session paused.` · `Return to Hyperfocus or exit.` · `Focus restored.` · `Mission complete.` · `Choose one task.` · `One task. One session.` · `Back to focus.`

Forbidden (MUST NOT appear anywhere user-visible): `You failed.` · `You got distracted again.` · `You lost control.` · `Try harder.` · `Focus better.` — and any equivalent shaming language. Strict, never shaming.

## 14. Intensity modes mapping (canon §8, locked)

| Aspect | calm | strict | cinematic |
|---|---|---|---|
| auraIntensity multiplier | 0.8× | 1.0× | 1.2× |
| alarm volume multiplier | 0.7× | 1.1× | 1.0× |
| voice style used in session | calm | strict | cinematic |
| countdown | standard fade | standard, faster | extra glow, slower scale, longer fades |

- Multipliers apply on top of user settings: aura per §4.1 formula; alarm volume = `hf.soundVolume × multiplier`, clamped to [0, 1].
- Voice style during a session is dictated by the session's intensity (this table), overriding `hf.voiceStyle`, which serves as the default/preview style outside sessions **[spec-defined]**. Voice parameters per style are locked in canon §6 (calm 0.45/1.0, strict 0.52/0.95, cinematic 0.42/0.85).
- The countdown column maps to the variants in §3.1.

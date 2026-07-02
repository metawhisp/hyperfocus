# PROGRESS.md — Ralph loop memory

> Read this file at the start of every iteration; rewrite the relevant sections at the end.
> Keep it short — this is working state, not a report.

## Current phase

**FLIGHT DECK shipped end-to-end + generated focus sound (canon #25–#29).** Focus sound solved:
our own Ambient Pad synth (PadSynth.swift) is the production default, 12 s perceptual swell on all
modes. Countdown intro shipped in matrix style (gallery variant A, canon #30). Open: user walkthrough
(real-camera attention test via HFCAM logs).

## What exists

- **Logic (62 unit tests green):** `SessionReducer` (T1–T18, accounting, camera degradation D1),
  `SessionTimer` (monotonic heartbeat), `OrbPositionStore`, `SessionStore`.
- **UI + services (implemented, build green, all 7 screens render-verified via ImageRenderer):**
  - `AppState` + `SessionCoordinator`: event → reducer → effects → services/windows.
  - Focus Orb (glass `NSPanel`, drag/click/edge-snap, always-on-top, position persistence).
  - Start card, cinematic countdown overlay, 4-window edge Aura Frame, Active HUD, Away card +
    recovery, Completion card, History, Settings (all §8 sections), Onboarding.
  - `VoicePromptService` (AVSpeech), `AlarmService` (AVAudioEngine brown noise),
    `CameraPresenceService` (AVCapture + Vision, privacy-safe, change-only 2 Hz),
    `SimulatedPresenceService`, `CameraPermissionService`.
  - MenuBarExtra with the DEBUG simulation submenu (canon §10); DEBUG-only `DebugSnapshots`
    renders screens to PNGs headlessly (HF_SNAPSHOT=1).

## Completed

- [x] Phase 0 — scaffold
- [x] All unit-testable TDD items (reducer/timer/stores) — 62 tests green
- [x] Phases 1–10 UI/coordinator/service items implemented; app builds, launches, runs; screens verified

## Next step (needs a human at the keyboard)

Live on-screen spot-check that ImageRenderer/unit tests can't cover:
1. Orb actually floats above other apps on all Spaces; drag + edge-snap feel right; position persists across relaunch.
2. Real-camera session: grant permission, confirm warning→away→recovery on the real camera, green dot off after end.
3. Aura click-through (clicks reach apps beneath); countdown darken/voice sync; alarm is a soft hum.
4. Multi-monitor / resolution-change hardening.
5. Plan item 10.6 (full BRIEF AC 1–30 manual walkthrough) and 10.7 (README "next improvements").

Run: `open Hyperfocus.xcodeproj` → Cmd+R. Debug menu → "Use Simulated Camera" is ON in DEBUG, so the
full green→yellow→red→alarm→recovery→completion flow is drivable with no camera.

## Known issues

- ImageRenderer snapshots show `TextField`/borderless-`Button` as yellow bars and dark title text —
  an ImageRenderer limitation only; the live compositor renders white text on blurred glass. Not an app bug.
- Computer-use screen control couldn't resolve this LSUIElement agent app this session, so live
  interaction wasn't automated — verified via ImageRenderer + unit tests + crash-free run instead.

## Decisions log

- Locked decisions & deviations: `specs/00-canon.md` §13.
- `SessionTimer` runs continuously active→completed; `.pauseTimer`/`.resumeTimer` are no-ops at the
  coordinator (reducer accounts per state) so recovery ticks keep flowing in away/recovering.
- Reducer stays pure (no `Date()`); coordinator/AppState stamp timestamps and persist.
- `DebugSnapshots.swift` added under Utilities as DEBUG-only verification tooling (outside the
  original canon §2 map; dev-only, compiled out of release).

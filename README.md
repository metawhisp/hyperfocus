# Hyperfocus

> Hyperfocus turns your Mac into a focus mode.
> **One click. One task. Enter Hyperfocus.**

Hyperfocus is a cinematic focus timer for macOS, designed for people with ADHD and for anyone who finds it hard to start a task, hold attention, and not drift out of work. Instead of a plain timer, it stages an entry into work: click the floating glass Focus Orb, type one task, and the screen darkens into a `3…2…1…FOCUS` countdown. While you work, a subtle green aura glows along the screen edges and the camera locally checks that you're still there — leave, and the timer pauses, the aura turns red, and a soft brown-noise alarm calls you back. Return, and focus resumes.

## MVP features

- **Floating Focus Orb** — small always-on-top glass dot; draggable, snaps to screen edges, remembers its position
- **Start Session Popover** — glass "Prepare Hyperfocus" card: Mission (required), Success condition (optional), duration presets 5/15/25/45 min + custom, Intensity (Calm / Strict / Cinematic)
- **Cinematic countdown** — fullscreen overlay, screen darkens, `ENTER HYPERFOCUS MODE` → `3` → `2` → `1` → `FOCUS`, with voice
- **Edge Aura Frame** — click-through glow on all four screen edges: green (active), yellow (warning), red (away), flash on completion
- **Active timer + HUD** — counts only real focus time; HUD shows mission, remaining time, camera status
- **Local face presence detection** — AVFoundation + Vision, processed on-device only; face missing 7 s → warning, 15 s → away
- **Away Mode** — timer pauses, red aura, looping soft brown-noise alarm, "Session paused" card with Return / Exit Session
- **Recovery** — 3 s of renewed presence resumes the session ("Focus restored.")
- **Voice prompts** — countdown, away, restored, complete lines via speech synthesis; Calm / Strict / Cinematic voice styles
- **Completion screen** — "Mission complete" with focus time, paused time, breaks, longest streak; mark Done / Partial / Not done, optional next action
- **Local session history** — sessions saved to a local JSON file, simple history list
- **Settings** — General / Focus / Camera / Sound / Visual / Data sections; thresholds, volumes, aura intensity, reduce motion, and more
- **No-camera fallback** — sessions work without camera in manual pause/resume mode
- **Debug simulation** — menu commands to simulate presence/away/return without a camera (DEBUG builds)

## Status

Specs and project scaffold are ready. Implementation is executed by AI coding agents working through the phase checklist in [`specs/05-implementation-plan.md`](specs/05-implementation-plan.md), following the rules in [`CLAUDE.md`](CLAUDE.md) / [`AGENTS.md`](AGENTS.md), with current state tracked in [`PROGRESS.md`](PROGRESS.md).

## Quick start

Requirements: macOS 15+, Xcode 16+.

```bash
brew install xcodegen        # once
xcodegen generate            # creates Hyperfocus.xcodeproj from project.yml
open Hyperfocus.xcodeproj
```

Run the `Hyperfocus` scheme from Xcode. The app has no Dock icon — look for the menu bar item and the floating orb. Grant camera permission when prompted (or start a no-camera session; the app never requires the camera).

## Running tests

```bash
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus test
```

Unit tests (`HyperfocusTests`) cover the session state machine, timer accounting, session persistence, and orb position storage.

## Documentation index

| File | Description |
|---|---|
| [`specs/BRIEF.md`](specs/BRIEF.md) | Original product brief — the source of product truth |
| [`specs/00-canon.md`](specs/00-canon.md) | Locked technical decisions: exact identifiers, thresholds, copy strings, file structure, settings keys. Wins on any technical detail conflict |
| `specs/01`–`06` | Detailed specs derived from the brief and canon (architecture, UI, services, plan) |
| [`specs/05-implementation-plan.md`](specs/05-implementation-plan.md) | Phase 1–10 implementation checklist — the work queue for coding agents |
| [`AGENTS.md`](AGENTS.md) | Entry point for AI coding agents: repo map, rules digest, bootstrap sequence |
| [`PROGRESS.md`](PROGRESS.md) | Living Ralph-loop memory file: current phase, next step, known issues |
| [`CLAUDE.md`](CLAUDE.md) | Working rules for implementing agents (Ralph loop, TDD, checklists, git discipline) |

## Project structure

```
project.yml                  # XcodeGen manifest — source of truth for the Xcode project
Hyperfocus/
  App/                       # @main, AppDelegate, AppState, SessionCoordinator
  Session/                   # state machine (reducer/events/effects), timer, config, persistence
  Orb/                       # Focus Orb window, view, position store
  Aura/                      # 4 edge glow windows + aura state
  UI/                        # start card, countdown, HUD, away card, completion, settings, onboarding, history
  Camera/                    # presence detection protocol, AVFoundation+Vision service, permissions, simulator
  Audio/                     # voice prompts (speech synthesis), brown-noise alarm (AVAudioEngine)
  Utilities/                 # panels, overlay windows, screen manager, settings store, constants
HyperfocusTests/             # reducer, timer, store unit tests
```

`Hyperfocus.xcodeproj` is generated and git-ignored — regenerate with `xcodegen generate`. The full locked file map is in [`specs/00-canon.md`](specs/00-canon.md) §2.

## Privacy

> Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally on your Mac. Hyperfocus does not record, save, or upload camera footage.

Hard product rules: no video recording, no frame saving, no upload, no cloud by default, no identity recognition, no emotion detection. The camera turns off when the session ends, and a no-camera mode is always available. The app contains no network code at all.

## Known limitations (MVP scope)

- **Single screen** — aura and overlays target the main screen only; no multi-screen aura
- **English only** — no localization
- **No cloud** — local-only session history; no sync, no accounts
- Also out of scope: team rooms, social focus sessions, subscriptions, payments, AI coach, website blocking, iPhone camera mode, advanced analytics, App Store payment flow, haptics

See [`specs/00-canon.md`](specs/00-canon.md) §12 for the authoritative out-of-scope list.

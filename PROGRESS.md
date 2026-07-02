# PROGRESS.md — Ralph loop memory

> Read this file at the start of every iteration; rewrite the relevant sections at the end.
> Keep it short — this is working state, not a report.

## Current phase

**Logic backbone complete. Next: UI + services + coordinator wiring (needs manual/GUI acceptance).**

The entire headless-unit-testable layer is implemented and green. What remains for each phase is
the AppKit/SwiftUI/AVFoundation glue whose acceptance is a manual run (specs/06 §1.2, §5, §6),
not an `xcodebuild test` assertion.

## What exists

- Full specs (`specs/BRIEF.md`, `specs/00-canon.md` canon, `specs/01`–`06`).
- XcodeGen scaffold; canonical enums/models, `Constants`, protocols, `KeyablePanel`, `SettingsStore`,
  `SessionStore` (all from Phase 0).
- **Implemented + unit-tested (62 tests green):**
  - `SessionReducer` — the whole state machine T1–T18, ordered effects, clamp→accrue→evaluate tick
    pipeline (T15 beats T8), presence debounce, no-camera + camera-loss (D1) degradation.
    `SessionContext` extended with config-snapshot thresholds, `cameraAvailable`, `nextAction`.
  - `SessionTimer` — 1 Hz monotonic tick source, injectable clock.
  - `OrbPositionStore` — JSON `{x,y}` persistence + clamp-to-visible-bounds.
  - `SessionStore` — full catalog verified (roundtrip, corrupt recovery, clear, order, dir creation).
  - Test files cover specs/06 §4.1–4.7 verbatim (names are D5-authoritative from §4).
- Everything else is still a compilable stub carrying `// IMPLEMENT — see plan Phase N`.

## Completed

- [x] Phase 0 — scaffold (project generates, skeleton compiles, baseline green)
- [x] **All unit-testable TDD items** — plan items 2.1, 3.1–3.3, 4.1–4.2, 6.1–6.6, 7.6, 8.1–8.5,
  9.1–9.2 (their Accept is "tests green"; now green). Ticked in `specs/05-implementation-plan.md`.

## Next step

Wire the reducer/timer/stores into running UI. Suggested order (all need a **GUI run to accept**):
1. **1.1–1.4** App shell: `AppState` + `SessionCoordinator` (event→reducer→effects→services),
   MenuBarExtra, `AppDelegate` orb bootstrap.
2. **2.2–2.5** Focus Orb window (drag/click/snap, uses `OrbPositionStore`).
3. **3.4–3.5, 4.3–4.5** Start card + countdown overlay + `VoicePromptService`.
4. **5.x** Aura windows; **6.7** timer↔coordinator wiring + HUD.
5. **7.1–7.5** camera + `SimulatedPresenceService` (debug menu makes the whole flow testable w/o camera).
6. **8.6–8.8** `AlarmService` + away card + end-to-end simulated run.
7. **9.3–9.5** completion card + save/reset + history; **10.x** settings, onboarding, polish.

The reducer is the source of truth — the coordinator should stay thin glue (canon §5). Snapshot the
three thresholds from `SettingsStore` into `SessionContext` at session start; stamp
`sessionStartTime`/`endedAt` in the coordinator (reducer is pure, no `Date()`).

## Known issues

- None. `xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus test` → 62/62 green.

## Decisions log

- Locked decisions & deviations: `specs/00-canon.md` §13 (incl. D1 camera degradation, D4 Double
  counters, D5 test-name authority).
- Reducer kept pure: no `Date()` inside `reduce` — coordinator stamps session timestamps.
- New deviations require updating `specs/00-canon.md` first (its own commit), then code.

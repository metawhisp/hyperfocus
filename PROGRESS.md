# PROGRESS.md — Ralph loop memory

> Read this file at the start of every iteration; rewrite the relevant sections at the end.
> Keep it short — this is working state, not a report.

## Current phase

**Phase 1 (App shell) — not started.**

## What exists

- Full specs: `specs/BRIEF.md` (product truth), `specs/00-canon.md` (technical truth),
  detailed specs `specs/01`–`06` including `specs/05-implementation-plan.md` (the checklist).
- XcodeGen scaffold: `project.yml` + compilable skeleton matching the module map in canon §2.
- Already FULLY implemented by the scaffold (not stubs): canonical enums/models per canon §4–§7
  (`SessionState`, `SessionEvent`, `SessionEffect`, `AuraState`, `CameraState`, `VoiceLine`,
  `CompletionStatus`, `Intensity`, `Session`, `SessionConfig`, `SessionContext`), `Constants`
  (every canon literal), the service protocols (`PresenceDetecting`, `VoicePrompting`,
  `AlarmPlaying`), `KeyablePanel`, `SettingsStore` (typed accessors with per-getter canon §8
  defaults), `SessionStore` (JSON persistence, injectable directory URL), and the `MenuBarExtra`
  skeleton with the populated `DEBUG` simulation submenu (placeholder no-op actions).
- Skeleton files intentionally contain `// IMPLEMENT — see plan Phase N` markers; they are the
  Phase-0 deliverable, not TODO-stub violations — remove each marker only when its plan item is closed.
- Green test baseline: `xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus test` passes.

## Completed

- [x] Phase 0 — scaffold
  - [x] `project.yml` generates `Hyperfocus.xcodeproj` via `xcodegen generate`
  - [x] File/module skeleton created per canon §2
  - [x] Canonical enums/structs compile
  - [x] `HyperfocusTests` target runs green

## Next step

Open `specs/05-implementation-plan.md` → **Phase 1 (App shell)** → execute the **first unchecked item** with TDD (red → green → refactor), then build + test, update this file, commit.

## Known issues

- None yet.

## Decisions log

- All locked decisions and intentional deviations from the BRIEF: `specs/00-canon.md` §13.
- New deviations require updating `specs/00-canon.md` first (its own commit), then code — never silently.

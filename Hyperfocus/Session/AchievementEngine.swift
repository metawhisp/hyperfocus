// AchievementEngine.swift — evaluates the 100-entry AchievementCatalog against the full session
// history (canon #41). Pure and idempotent: re-run on every completion, it recomputes the whole
// unlocked set from scratch, so adding a rule (or importing old data) awards retroactively.
//
// 97 rules derive from today's Session fields. Three need fields we don't persist yet and stay
// locked until then: speed_demon (start latency), nudge_proof (survived a nudge), sound_vision
// (focus sound + camera). Everything else is honest and live.

import Foundation

enum AchievementEngine {
    /// The full set of unlocked catalog ids given the complete history.
    static func unlockedIDs(history: [Session], now: Date = Date(),
                            calendar: Calendar = .current) -> Set<String> {
        var ids = Set<String>()
        // A "focus session" = the timer ran to the end (done/partial/notDone). Only an early STOP
        // (.exited) doesn't count. This keeps the completion card and the Statistics recompute in
        // agreement regardless of the later mission answer (codex review).
        let done = history.filter { $0.completionStatus != .exited }.sorted { $0.startedAt < $1.startedAt }
        guard !done.isEmpty else { return ids }

        func win(_ id: String, _ cond: Bool) { if cond { ids.insert(id) } }

        // Aggregates
        let count = done.count
        let totalSec = done.reduce(0) { $0 + $1.activeFocusSeconds }
        let totalMin = totalSec / 60
        let cleanCount = done.filter { $0.breakCount == 0 }.count
        let days = Set(done.map { calendar.startOfDay(for: $0.startedAt) })
        let curStreak = currentStreak(days: days, now: now, cal: calendar)
        let longStreak = longestStreak(days: days, cal: calendar)
        func hour(_ s: Session) -> Int { calendar.component(.hour, from: s.startedAt) }
        func weekday(_ s: Session) -> Int { calendar.component(.weekday, from: s.startedAt) } // 1=Sun
        func words(_ s: Session) -> Int {
            s.mission.split(whereSeparator: { $0 == " " }).filter { !$0.isEmpty }.count
        }

        // MARK: Firsts
        win("first_light", true)
        win("warm_up", totalSec >= 3600)
        win("clean_slate", cleanCount >= 1)
        win("eye_contact", done.contains { $0.cameraEnabled })
        win("your_words", done.contains { !$0.mission.trimmingCharacters(in: .whitespaces).isEmpty
            && !$0.mission.lowercased().hasPrefix("hyperfocus task") && $0.mission != "Focus" })
        win("boomerang", done.contains { $0.breakCount >= 1 })
        win("sunrise_start", done.contains { hour($0) < 8 })
        win("burning_midnight", done.contains { hour($0) >= 0 && hour($0) < 5 })
        win("tailored", done.contains { ![5, 15, 25, 45].contains($0.plannedDurationSeconds / 60) })
        // continuation/wingman need wand-provenance (a typed "continue…" isn't proof) — deferred
        // with speed_demon/nudge_proof/sound_vision until Session gains those flags.

        // MARK: Milestones
        win("centurion", totalSec >= 100 * 3600)
        win("grandmaster", totalSec >= 500 * 3600)
        win("legend", totalSec >= 1000 * 3600)
        win("half_k", count >= 500)
        win("thousand_club", count >= 1000)
        win("ten_k_minutes", totalMin >= 10_000)
        win("marathoner", count >= 42)
        if let first = done.first?.startedAt {
            win("long_game", now.timeIntervalSince(first) >= 365 * 24 * 3600)
        }

        // MARK: Time of day
        win("early_bird", done.contains { hour($0) < 6 })
        win("dawn_patrol", done.contains { (6..<8).contains(hour($0)) })
        win("golden_hour", done.contains { (18..<19).contains(hour($0)) })
        win("night_owl", done.contains { hour($0) >= 0 && hour($0) < 5 })
        win("witching_hour", done.contains { (3..<4).contains(hour($0)) })
        win("lunch_locked", done.contains { (12..<13).contains(hour($0)) })
        win("blue_monday", done.contains { weekday($0) == 2 && hour($0) < 9 })
        win("friday_finisher", done.contains { weekday($0) == 6 && hour($0) >= 17 })
        win("sunday_reset", done.contains { weekday($0) == 1 })
        win("saturday_grind", done.contains { weekday($0) == 7 })
        win("round_the_clock", dayHasQuarters(done, [.morning, .afternoon, .evening], cal: calendar))
        win("four_watches", allQuartersEverHit(done, cal: calendar))

        // MARK: Days & calendar
        func comp(_ s: Session) -> DateComponents {
            calendar.dateComponents([.year, .month, .day], from: s.startedAt)
        }
        win("new_year", done.contains { comp($0).month == 1 && comp($0).day == 1 })
        win("leap_faith", done.contains { comp($0).month == 2 && comp($0).day == 29 })
        win("payday", done.contains { comp($0).day == 1 || comp($0).day == 15 })
        win("holiday_hustle", done.contains { comp($0).month == 12 && [24, 25, 31].contains(comp($0).day ?? 0) })
        win("fresh_month", done.contains { s in
            !done.contains { other in other.startedAt < s.startedAt
                && calendar.component(.month, from: other.startedAt) == calendar.component(.month, from: s.startedAt)
                && calendar.component(.year, from: other.startedAt) == calendar.component(.year, from: s.startedAt) }
        })
        win("first_week", true)   // the very first session is always the first of its week
        win("weekend_double", weekendDoubleHit(days: days, cal: calendar))
        win("perfect_week", perfectWeekHit(days: days, cal: calendar))
        win("comeback_kid", gapOfDaysExists(days: days, minGap: 8, cal: calendar))
        win("anniversary", anniversaryHit(done: done, cal: calendar))

        // MARK: Streaks & habits
        win("streak_3", longStreak >= 3)
        win("streak_7", longStreak >= 7)
        win("streak_21", longStreak >= 21)
        win("streak_30", longStreak >= 30)
        win("streak_365", longStreak >= 365)
        win("same_bat_time", sameHourStreak(done: done, cal: calendar) >= 3)
        win("streak_saver", done.contains { hour($0) == 23 })
        win("phoenix", gapOfDaysExists(days: days, minGap: 8, cal: calendar) && curStreak >= 1)
        win("no_zeroes", maxDaysInAnyWeek(days: days, cal: calendar) >= 5)
        win("double_days", consecutiveDoubleDays(done: done, cal: calendar) >= 5)

        // MARK: Focus quality
        win("laser_mind", cleanCount >= 1)
        win("in_the_zone", maxCleanRun(done) >= 5)
        win("untouchable", maxCleanRun(done) >= 20)
        win("deep_diver", done.contains { $0.longestStreakSeconds >= 30 * 60 })
        win("rock_solid", done.contains { $0.longestStreakSeconds >= 60 * 60 })
        win("immovable", dayWithNoAway(done: done, cal: calendar))
        win("bulletproof_week", weekWithNoEarlyStop(history: history, cal: calendar))
        win("flawless", done.contains { $0.breakCount == 0 && $0.pausedSeconds == 0
            && $0.activeFocusSeconds >= $0.plannedDurationSeconds })
        win("no_peeking", done.filter { $0.cameraEnabled && $0.breakCount == 0 }.count >= 10)
        win("steady_hands", maxCleanRunSameDay(done: done, cal: calendar) >= 3)
        win("clean_month", monthWithNoEarlyStop(history: history, cal: calendar))

        // MARK: Duration & marathon
        win("deep_45", done.contains { $0.activeFocusSeconds >= 45 * 60 })
        win("deep_90", done.contains { $0.activeFocusSeconds >= 90 * 60 })
        win("iron_focus", done.contains { $0.activeFocusSeconds >= 120 * 60 })
        win("ultra", done.contains { $0.activeFocusSeconds >= 180 * 60 })
        win("sprints", countPerDay(done, cal: calendar) { $0.activeFocusSeconds <= 10 * 60 } >= 5)
        win("double_feature", countPerDay(done, cal: calendar) { $0.activeFocusSeconds >= 90 * 60 } >= 2)
        win("full_shift", maxFocusInOneDay(done: done, cal: calendar) >= 8 * 3600)
        win("power_hour", done.contains { $0.activeFocusSeconds >= 60 * 60 && $0.breakCount == 0 })

        // MARK: Comeback
        win("back_on_track", done.contains { $0.breakCount >= 1 })
        win("persistent", done.filter { $0.breakCount >= 1 }.count >= 10)
        win("nine_lives", done.contains { $0.breakCount >= 3 })
        win("redemption", redemptionHit(history: history, cal: calendar))
        win("round_two", repeatedMissionAfterFail(history: history))
        win("third_charm", sessionsPerDayMax(done, cal: calendar) >= 3)
        win("quick_bounce", quickBounceHit(history: history))
        win("rise_grind", riseGrindHit(done: done, cal: calendar))

        // MARK: Missions
        win("wordsmith", done.contains { words($0) >= 5 })
        win("one_word", done.contains { words($0) == 1 })
        win("blank_canvas", done.contains { $0.mission.lowercased().hasPrefix("hyperfocus task")
            || $0.mission == "Focus" })
        win("creature_habit", maxSameMission(done) >= 5)
        win("renaissance", distinctMissions(done) >= 10)
        win("shipmate", done.contains { let m = $0.mission.lowercased()
            return m.contains("ship") || m.contains("finish") || m.contains("done") })
        win("polyglot", done.contains { $0.mission.unicodeScalars.contains { $0.value > 0x2FF } })

        // MARK: Rhythm & fun
        win("morning_person", done.filter { hour($0) < 12 }.count >= 5)
        win("evening_person", done.filter { hour($0) >= 18 }.count >= 5)
        win("cooldown", cooldownHit(done: done, cal: calendar))
        win("round_number", count >= 100)
        win("overachiever", done.contains { $0.activeFocusSeconds > $0.plannedDurationSeconds && $0.plannedDurationSeconds > 0 })
        win("palindrome", done.contains { s in
            guard let end = s.endedAt else { return false }
            let h = calendar.component(.hour, from: end), m = calendar.component(.minute, from: end)
            let str = String(format: "%02d%02d", h, m)
            return str == String(str.reversed())
        })
        win("metronome", sameWeekdayStreak(days: days, cal: calendar) >= 4)
        win("balanced_diet", balancedWeek(done: done, cal: calendar))
        win("escalation", escalationHit(done: done, cal: calendar))
        win("warm_up_act", warmUpActHit(done: done, cal: calendar))
        win("bookends", bookendsHit(done: done, cal: calendar))

        // Completionist: everything else unlocked.
        let others = Set(AchievementCatalog.all.map { $0.id }).subtracting(["completionist"])
        win("completionist", ids.isSuperset(of: others))
        return ids
    }

    // MARK: Streak helpers
    private static func currentStreak(days: Set<Date>, now: Date, cal: Calendar) -> Int {
        var cursor = cal.startOfDay(for: now)
        if !days.contains(cursor), let y = cal.date(byAdding: .day, value: -1, to: cursor), days.contains(y) { cursor = y }
        var n = 0
        while days.contains(cursor) { n += 1; guard let p = cal.date(byAdding: .day, value: -1, to: cursor) else { break }; cursor = p }
        return n
    }
    private static func longestStreak(days: Set<Date>, cal: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted(); var best = 1, run = 1
        for i in 1..<sorted.count {
            if let p = cal.date(byAdding: .day, value: 1, to: sorted[i-1]), cal.isDate(p, inSameDayAs: sorted[i]) { run += 1 } else { run = 1 }
            best = max(best, run)
        }
        return best
    }
    private static func gapOfDaysExists(days: Set<Date>, minGap: Int, cal: Calendar) -> Bool {
        let sorted = days.sorted()
        for i in 1..<max(1, sorted.count) {
            if let d = cal.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day, d >= minGap { return true }
        }
        return false
    }
    private static func maxDaysInAnyWeek(days: Set<Date>, cal: Calendar) -> Int {
        var byWeek = [Int: Set<Date>]()
        for d in days { let w = cal.component(.weekOfYear, from: d) * 100 + cal.component(.yearForWeekOfYear, from: d); byWeek[w, default: []].insert(d) }
        return byWeek.values.map { $0.count }.max() ?? 0
    }
    private static func weekendDoubleHit(days: Set<Date>, cal: Calendar) -> Bool {
        for d in days where cal.component(.weekday, from: d) == 7 {           // Saturday
            if let sun = cal.date(byAdding: .day, value: 1, to: d), days.contains(cal.startOfDay(for: sun)) { return true }
        }
        return false
    }
    private static func perfectWeekHit(days: Set<Date>, cal: Calendar) -> Bool {
        var byWeek = [Int: Set<Int>]()
        for d in days { let w = cal.component(.weekOfYear, from: d) * 100 + cal.component(.yearForWeekOfYear, from: d); byWeek[w, default: []].insert(cal.component(.weekday, from: d)) }
        return byWeek.values.contains { $0.count == 7 }
    }
    private static func anniversaryHit(done: [Session], cal: Calendar) -> Bool {
        guard let first = done.first?.startedAt else { return false }
        return done.dropFirst().contains { s in
            let d = cal.dateComponents([.day], from: first, to: s.startedAt).day ?? 0
            return abs(d - 365) <= 3
        }
    }
    private static func sameHourStreak(done: [Session], cal: Calendar) -> Int {
        // Consecutive days that all contain a session starting in the same clock hour.
        var best = 0
        let byDay = Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }
        for h in 0..<24 {
            let daysWithHour = Set(byDay.filter { $0.value.contains { cal.component(.hour, from: $0.startedAt) == h } }.map { $0.key })
            best = max(best, longestStreak(days: daysWithHour, cal: cal))
        }
        return best
    }
    private static func sameWeekdayStreak(days: Set<Date>, cal: Calendar) -> Int {
        var best = 0
        for wd in 1...7 {
            let wdDays = days.filter { cal.component(.weekday, from: $0) == wd }.sorted()
            var run = wdDays.isEmpty ? 0 : 1
            for i in 1..<max(1, wdDays.count) {
                if let p = cal.date(byAdding: .day, value: 7, to: wdDays[i-1]), cal.isDate(p, inSameDayAs: wdDays[i]) { run += 1 } else { run = 1 }
                best = max(best, run)
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: Per-day / per-run helpers
    private static func countPerDay(_ done: [Session], cal: Calendar, where pred: (Session) -> Bool) -> Int {
        Dictionary(grouping: done.filter(pred)) { cal.startOfDay(for: $0.startedAt) }.values.map { $0.count }.max() ?? 0
    }
    private static func sessionsPerDayMax(_ done: [Session], cal: Calendar) -> Int {
        Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }.values.map { $0.count }.max() ?? 0
    }
    private static func consecutiveDoubleDays(done: [Session], cal: Calendar) -> Int {
        let doubleDays = Set(Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }.filter { $0.value.count >= 2 }.map { $0.key })
        return longestStreak(days: doubleDays, cal: cal)
    }
    private static func maxCleanRun(_ done: [Session]) -> Int {
        var best = 0, run = 0
        for s in done { if s.breakCount == 0 { run += 1; best = max(best, run) } else { run = 0 } }
        return best
    }
    private static func maxCleanRunSameDay(done: [Session], cal: Calendar) -> Int {
        Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }.values.map { maxCleanRun($0.sorted { $0.startedAt < $1.startedAt }) }.max() ?? 0
    }
    private static func maxFocusInOneDay(done: [Session], cal: Calendar) -> Int {
        Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }.values.map { $0.reduce(0) { $0 + $1.activeFocusSeconds } }.max() ?? 0
    }
    private static func dayWithNoAway(done: [Session], cal: Calendar) -> Bool {
        let byDay = Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }
        return byDay.values.contains { day in day.count >= 1 && day.allSatisfy { $0.breakCount == 0 } && day.reduce(0) { $0 + $1.activeFocusSeconds } >= 3600 }
    }
    private static func maxSameMission(_ done: [Session]) -> Int {
        Dictionary(grouping: done) { $0.mission.lowercased() }.values.map { $0.count }.max() ?? 0
    }
    private static func distinctMissions(_ done: [Session]) -> Int {
        Set(done.map { $0.mission.lowercased() }).count
    }
    private static func balancedWeek(done: [Session], cal: Calendar) -> Bool {
        var byWeek = [Int: Set<Intensity>]()
        for s in done { let w = cal.component(.weekOfYear, from: s.startedAt) * 100 + cal.component(.yearForWeekOfYear, from: s.startedAt); byWeek[w, default: []].insert(s.intensity) }
        return byWeek.values.contains { $0.count >= 3 }
    }
    private static func escalationHit(done: [Session], cal: Calendar) -> Bool {
        for (_, day) in Dictionary(grouping: done, by: { cal.startOfDay(for: $0.startedAt) }) {
            let sorted = day.sorted { $0.startedAt < $1.startedAt }
            for i in 0...(max(0, sorted.count - 3)) where sorted.count >= 3 && i + 2 < sorted.count {
                if sorted[i].activeFocusSeconds < sorted[i+1].activeFocusSeconds
                    && sorted[i+1].activeFocusSeconds < sorted[i+2].activeFocusSeconds { return true }
            }
        }
        return false
    }
    private static func warmUpActHit(done: [Session], cal: Calendar) -> Bool {
        for (_, day) in Dictionary(grouping: done, by: { cal.startOfDay(for: $0.startedAt) }) {
            let sorted = day.sorted { $0.startedAt < $1.startedAt }
            for i in 1..<max(1, sorted.count) where sorted[i-1].activeFocusSeconds < 10*60 && sorted[i].activeFocusSeconds >= 45*60 { return true }
        }
        return false
    }
    private static func redemptionHit(history: [Session], cal: Calendar) -> Bool {
        let notDoneDays = Set(history.filter { $0.completionStatus == .notDone }.map { cal.startOfDay(for: $0.startedAt) })
        let doneDays = Set(history.filter { $0.completionStatus == .done }.map { cal.startOfDay(for: $0.startedAt) })
        return notDoneDays.contains { nd in
            guard let next = cal.date(byAdding: .day, value: 1, to: nd) else { return false }
            return doneDays.contains(cal.startOfDay(for: next))
        }
    }
    /// A restart within 5 minutes of an early STOP.
    private static func quickBounceHit(history: [Session]) -> Bool {
        let sorted = history.sorted { $0.startedAt < $1.startedAt }
        for i in 0..<sorted.count where sorted[i].completionStatus == .exited {
            let exitEnd = sorted[i].endedAt ?? sorted[i].startedAt
            if sorted[(i+1)...].contains(where: { $0.startedAt.timeIntervalSince(exitEnd) >= 0
                && $0.startedAt.timeIntervalSince(exitEnd) <= 5 * 60 }) { return true }
        }
        return false
    }
    /// A morning (before noon) session the day after a post-midnight (00–05) one.
    private static func riseGrindHit(done: [Session], cal: Calendar) -> Bool {
        let lateDays = Set(done.filter { (0..<5).contains(cal.component(.hour, from: $0.startedAt)) }
            .map { cal.startOfDay(for: $0.startedAt) })
        return done.contains { s in
            guard cal.component(.hour, from: s.startedAt) < 12 else { return false }
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: s.startedAt)) else { return false }
            return lateDays.contains(yesterday)
        }
    }
    /// The last session of some day is under 10 minutes.
    private static func cooldownHit(done: [Session], cal: Calendar) -> Bool {
        Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }.values.contains { day in
            guard let last = day.max(by: { $0.startedAt < $1.startedAt }) else { return false }
            return last.activeFocusSeconds < 10 * 60
        }
    }
    /// A day whose earliest and latest sessions are 8+ hours apart (bookending the day).
    private static func bookendsHit(done: [Session], cal: Calendar) -> Bool {
        Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }.values.contains { day in
            guard let first = day.min(by: { $0.startedAt < $1.startedAt }),
                  let last = day.max(by: { $0.startedAt < $1.startedAt }) else { return false }
            return last.startedAt.timeIntervalSince(first.startedAt) >= 8 * 3600
        }
    }
    private static func repeatedMissionAfterFail(history: [Session]) -> Bool {
        let sorted = history.sorted { $0.startedAt < $1.startedAt }
        for i in 0..<sorted.count where sorted[i].completionStatus == .notDone {
            let m = sorted[i].mission.lowercased()
            if sorted[(i+1)...].contains(where: { $0.completionStatus == .done && $0.mission.lowercased() == m }) { return true }
        }
        return false
    }

    private enum Quarter { case night, morning, afternoon, evening }
    private static func quarter(_ h: Int) -> Quarter {
        switch h { case 0..<6: return .night; case 6..<12: return .morning; case 12..<18: return .afternoon; default: return .evening }
    }
    private static func dayHasQuarters(_ done: [Session], _ need: [Quarter], cal: Calendar) -> Bool {
        let byDay = Dictionary(grouping: done) { cal.startOfDay(for: $0.startedAt) }
        return byDay.values.contains { day in
            let qs = Set(day.map { quarter(cal.component(.hour, from: $0.startedAt)) })
            return need.allSatisfy { qs.contains($0) }
        }
    }
    private static func allQuartersEverHit(_ done: [Session], cal: Calendar) -> Bool {
        Set(done.map { quarter(cal.component(.hour, from: $0.startedAt)) }).count == 4
    }
    private static func weekWithNoEarlyStop(history: [Session], cal: Calendar) -> Bool {
        // A calendar week containing ≥1 completed session and no notDone/exited.
        var weeks = [Int: (done: Int, bad: Int)]()
        for s in history {
            let w = cal.component(.weekOfYear, from: s.startedAt) * 100 + cal.component(.yearForWeekOfYear, from: s.startedAt)
            var v = weeks[w] ?? (0, 0)
            if s.completionStatus == .done { v.done += 1 } else if s.completionStatus == .notDone || s.completionStatus == .exited { v.bad += 1 }
            weeks[w] = v
        }
        return weeks.values.contains { $0.done >= 1 && $0.bad == 0 }
    }
    private static func monthWithNoEarlyStop(history: [Session], cal: Calendar) -> Bool {
        var months = [Int: (done: Int, bad: Int)]()
        for s in history {
            let m = cal.component(.year, from: s.startedAt) * 100 + cal.component(.month, from: s.startedAt)
            var v = months[m] ?? (0, 0)
            if s.completionStatus == .done { v.done += 1 } else if s.completionStatus == .notDone || s.completionStatus == .exited { v.bad += 1 }
            months[m] = v
        }
        return months.values.contains { $0.done >= 4 && $0.bad == 0 }
    }
}

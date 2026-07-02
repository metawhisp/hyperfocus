// AchievementsStore.swift — local achievements engine (canon #29): pixel badges for completed
// hyperfocus sessions. Evaluated when a session's timer reaches zero; stored as JSON next to
// sessions.json. Early exits are not celebrated — they increment the "burned" counter.

import Foundation

struct Achievement: Codable, Identifiable, Equatable {
    let id: String        // rule id, stable
    let title: String     // "LASER MIND"
    let detail: String    // "zero drifts"
    let icon: String      // PixelIcon key: flame|bolt|star|skull|sun|moon|target
    let unlockedAt: Date
}

final class AchievementsStore {
    private let directoryURL: URL
    private var fileURL: URL { directoryURL.appendingPathComponent("achievements.json") }

    private struct State: Codable {
        var unlocked: [Achievement] = []
        var burnedCount: Int = 0      // early exits (STOP) — counted, never celebrated
    }

    private var state = State()

    init(directoryURL: URL = SessionStore.defaultDirectoryURL()) {
        self.directoryURL = directoryURL
        load()
    }

    var unlocked: [Achievement] { state.unlocked }
    var burnedCount: Int { state.burnedCount }

    /// Most recent badges for the completion card's row.
    func recentBadges(limit: Int = 3) -> [Achievement] {
        Array(state.unlocked.suffix(limit).reversed())
    }

    func registerBurned() {
        state.burnedCount += 1
        save()
    }

    /// Called when a session's TIMER completes (before the mission answer). Returns new unlocks.
    /// `context` carries the just-finished session's counters; `history` is all saved sessions
    /// (completed ones have completionStatus != .exited).
    func evaluateCompletion(planned: Int, activeFocus: Int, breaks: Int,
                            startedAt: Date, history: [Session]) -> [Achievement] {
        let completedHistory = history.filter { $0.completionStatus != .exited }
        let now = Date()
        let calendar = Calendar.current
        var new: [Achievement] = []

        func unlock(_ id: String, _ title: String, _ detail: String, _ icon: String) {
            guard !state.unlocked.contains(where: { $0.id == id }) else { return }
            let a = Achievement(id: id, title: title, detail: detail, icon: icon, unlockedAt: now)
            state.unlocked.append(a)
            new.append(a)
        }

        // Firsts
        if completedHistory.isEmpty { unlock("first_session", "IGNITION", "first hyperfocus", "star") }
        if planned >= 15 * 60 { unlock("first_15m", "FIRST 15M", "quarter-hour deep", "bolt") }
        if planned >= 25 * 60 { unlock("first_25m", "FIRST 25M", "full pomodoro", "bolt") }
        if planned >= 45 * 60 { unlock("first_45m", "FIRST 45M", "deep dive", "bolt") }

        // Quality
        if breaks == 0 { unlock("laser_mind", "LASER MIND", "zero drifts", "bolt") }
        if breaks >= 1 { unlock("comeback", "COMEBACK", "drifted but finished", "target") }

        // Volume (total focus including this session)
        let totalSeconds = completedHistory.reduce(activeFocus) { $0 + $1.activeFocusSeconds }
        if totalSeconds >= 3600 { unlock("hour_1", "HOUR ONE", "1h total focus", "flame") }
        if totalSeconds >= 5 * 3600 { unlock("hour_5", "FIVE HOURS", "5h total focus", "flame") }
        if totalSeconds >= 10 * 3600 { unlock("hour_10", "TEN HOURS", "10h total focus", "flame") }

        // Rhythm — completed sessions today (incl. this one)
        let today = completedHistory.filter { calendar.isDate($0.startedAt, inSameDayAs: now) }.count + 1
        if today >= 2 { unlock("today_2", "DOUBLE", "2 in a day", "star") }
        if today >= 3 { unlock("today_3", "TRIPLE", "3 in a day", "star") }
        if today >= 5 { unlock("today_5", "MACHINE", "5 in a day", "star") }

        // Day streak (consecutive calendar days with ≥1 completed session, ending today)
        var streakDays = 1
        var day = calendar.startOfDay(for: now)
        while true {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            let hasSession = completedHistory.contains {
                calendar.isDate($0.startedAt, inSameDayAs: prev)
            }
            if hasSession { streakDays += 1; day = prev } else { break }
        }
        if streakDays >= 2 { unlock("streak_2", "STREAK ×2", "2 days in a row", "flame") }
        if streakDays >= 3 { unlock("streak_3", "STREAK ×3", "3 days in a row", "flame") }
        if streakDays >= 7 { unlock("streak_7", "STREAK ×7", "a full week", "flame") }

        // Time of day
        let hour = calendar.component(.hour, from: startedAt)
        if hour < 9 { unlock("early_bird", "EARLY BIRD", "before 9:00", "sun") }
        if hour >= 22 { unlock("night_owl", "NIGHT OWL", "after 22:00", "moon") }

        if !new.isEmpty { save() }
        return new
    }

    /// Current consecutive-day streak (for the flame badge counter).
    func dayStreak(history: [Session], now: Date = Date()) -> Int {
        let completed = history.filter { $0.completionStatus != .exited }
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: now)
        while completed.contains(where: { calendar.isDate($0.startedAt, inSameDayAs: day) }) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        state = (try? decoder.decode(State.self, from: data)) ?? State()
    }

    private func save() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

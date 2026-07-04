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

    /// Re-evaluate the full 100-entry catalog against the given history (which must INCLUDE the
    /// just-completed session). Idempotent — awards any newly-satisfied achievements (retroactive)
    /// and returns only the fresh unlocks for the completion card.
    func evaluate(fullHistory: [Session], now: Date = Date()) -> [Achievement] {
        let unlockedIDs = AchievementEngine.unlockedIDs(history: fullHistory, now: now)
        let already = Set(state.unlocked.map { $0.id })
        var new: [Achievement] = []
        for id in unlockedIDs.subtracting(already) {
            guard let entry = AchievementCatalog.all.first(where: { $0.id == id }) else { continue }
            let a = Achievement(id: entry.id, title: entry.title, detail: entry.detail,
                                icon: entry.icon, unlockedAt: now)
            state.unlocked.append(a)
            new.append(a)
        }
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

// StatsService.swift — read-only aggregator over the session history for the Statistics window
// (canon #41). Pure computation from SessionStore.all(); no persistence of its own.

import Foundation

struct FocusStats {
    var totalFocusSeconds: Int = 0
    var sessionCount: Int = 0
    var currentStreakDays: Int = 0
    var longestStreakDays: Int = 0
    var bestHour: Int? = nil            // 0…23, the hour with the most completed sessions
    var laserRate: Double = 0           // fraction of completed sessions with zero drifts
    var weeklyMinutes: [Double] = Array(repeating: 0, count: 7)   // Mon…Sun of the current week

    var totalFocusText: String {
        let h = totalFocusSeconds / 3600, m = (totalFocusSeconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    var bestHourText: String { bestHour.map { String(format: "%02d:00", $0) } ?? "—" }
    var laserRateText: String { "\(Int((laserRate * 100).rounded()))%" }
}

enum StatsService {
    /// Only sessions the user actually completed count toward focus stats.
    static func compute(from history: [Session], now: Date = Date(),
                        calendar: Calendar = .current) -> FocusStats {
        var s = FocusStats()
        let completed = history.filter { $0.completionStatus == .done }
        s.sessionCount = completed.count
        s.totalFocusSeconds = completed.reduce(0) { $0 + $1.activeFocusSeconds }

        // Laser rate: zero-drift share of completed sessions.
        if !completed.isEmpty {
            let clean = completed.filter { $0.breakCount == 0 }.count
            s.laserRate = Double(clean) / Double(completed.count)
        }

        // Best hour: mode of the start hour across completed sessions.
        var hourCounts = [Int: Int]()
        for session in completed {
            let h = calendar.component(.hour, from: session.startedAt)
            hourCounts[h, default: 0] += 1
        }
        s.bestHour = hourCounts.max { a, b in
            a.value != b.value ? a.value < b.value : a.key > b.key
        }?.key

        // Streaks: consecutive calendar days ending today that have ≥1 completed session.
        let daysWithFocus = Set(completed.map { calendar.startOfDay(for: $0.startedAt) })
        s.currentStreakDays = streak(endingAt: calendar.startOfDay(for: now),
                                     in: daysWithFocus, calendar: calendar)
        s.longestStreakDays = longestStreak(in: daysWithFocus, calendar: calendar)

        // This week's minutes per weekday (Mon…Sun), completed sessions only.
        let weekStart = startOfWeek(for: now, calendar: calendar)
        for session in completed {
            let day = calendar.startOfDay(for: session.startedAt)
            guard day >= weekStart,
                  let idx = calendar.dateComponents([.day], from: weekStart, to: day).day,
                  (0..<7).contains(idx) else { continue }
            s.weeklyMinutes[idx] += Double(session.activeFocusSeconds) / 60
        }
        return s
    }

    // MARK: Streak helpers

    private static func streak(endingAt day: Date, in days: Set<Date>, calendar: Calendar) -> Int {
        // Allow the streak to be "alive" if today has no session yet but yesterday did.
        var cursor = day
        if !days.contains(cursor), let y = calendar.date(byAdding: .day, value: -1, to: cursor),
           days.contains(y) {
            cursor = y
        }
        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    private static func longestStreak(in days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1, run = 1
        for i in 1..<sorted.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               calendar.isDate(prev, inSameDayAs: sorted[i]) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    /// Monday-based start of the week containing `date`.
    private static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: start)   // 1=Sun…7=Sat
        let offset = (weekday + 5) % 7                            // days since Monday
        return calendar.date(byAdding: .day, value: -offset, to: start) ?? start
    }
}

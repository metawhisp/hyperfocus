// AchievementCatalog.swift — the 100 unique achievements (canon #41, specs/achievements-catalog.md).
// Single source of truth: the Statistics window renders every entry (unlocked ones from
// AchievementsStore light up); the engine unlocks by these exact ids. `tier` only tints the badge.

import SwiftUI

enum BadgeTier { case bronze, silver, gold
    var color: Color {
        switch self { case .bronze: return FD.lime; case .silver: return FD.amber; case .gold: return FD.redLED }
    }
}

struct CatalogEntry: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String        // Achievement.icon key: flame|bolt|star|skull|sun|moon|target
    let tier: BadgeTier
}

enum AchievementCatalog {
    static let families: [(String, [CatalogEntry])] = [
        ("FIRSTS", [
            e("first_light", "FIRST LIGHT", "your first session", "target", .bronze),
            e("warm_up", "WARM-UP", "1 hour of total focus", "flame", .bronze),
            e("clean_slate", "CLEAN SLATE", "first zero-drift session", "star", .bronze),
            e("eye_contact", "EYE CONTACT", "first session with camera", "target", .bronze),
            e("your_words", "YOUR WORDS", "first custom mission", "star", .bronze),
            e("boomerang", "BOOMERANG", "first return after drifting", "target", .bronze),
            e("sunrise_start", "SUNRISE START", "first before 08:00", "sun", .bronze),
            e("burning_midnight", "BURNING MIDNIGHT", "first after 00:00", "moon", .bronze),
            e("tailored", "TAILORED", "first custom duration", "star", .bronze),
            e("wingman", "WINGMAN", "first from a wand suggestion", "bolt", .bronze),
        ]),
        ("MILESTONES", [
            e("centurion", "CENTURION", "100 hours total", "flame", .silver),
            e("grandmaster", "GRANDMASTER", "500 hours total", "flame", .gold),
            e("legend", "LEGEND", "1,000 hours total", "skull", .gold),
            e("half_k", "HALF-K", "500 sessions", "bolt", .silver),
            e("thousand_club", "THOUSAND CLUB", "1,000 sessions", "bolt", .gold),
            e("ten_k_minutes", "TEN-K MINUTES", "10,000 focused minutes", "flame", .silver),
            e("marathoner", "MARATHONER", "42 sessions", "star", .silver),
            e("long_game", "THE LONG GAME", "1 year since first", "sun", .gold),
        ]),
        ("TIME OF DAY", [
            e("early_bird", "EARLY BIRD", "before 06:00", "sun", .bronze),
            e("dawn_patrol", "DAWN PATROL", "06:00–08:00", "sun", .bronze),
            e("golden_hour", "GOLDEN HOUR", "18:00–19:00", "sun", .bronze),
            e("night_owl", "NIGHT OWL", "after 00:00", "moon", .bronze),
            e("witching_hour", "WITCHING HOUR", "03:00–04:00", "moon", .silver),
            e("lunch_locked", "LUNCH LOCKED-IN", "12:00–13:00", "sun", .bronze),
            e("blue_monday", "BLUE MONDAY BEATER", "Mon before 09:00", "bolt", .silver),
            e("friday_finisher", "FRIDAY FINISHER", "Friday evening", "star", .bronze),
            e("sunday_reset", "SUNDAY RESET", "a Sunday session", "sun", .bronze),
            e("saturday_grind", "SATURDAY GRIND", "a Saturday session", "flame", .bronze),
            e("round_the_clock", "ROUND THE CLOCK", "morn+aft+eve in a day", "target", .silver),
            e("four_watches", "ALL FOUR WATCHES", "every quarter of the day", "moon", .gold),
        ]),
        ("DAYS & CALENDAR", [
            e("new_year", "NEW YEAR, NEW FOCUS", "session on Jan 1", "star", .silver),
            e("leap_faith", "LEAP OF FAITH", "session on Feb 29", "star", .gold),
            e("fresh_month", "FRESH MONTH", "first of a month", "sun", .bronze),
            e("first_week", "FIRST OF THE WEEK", "first of a week", "sun", .bronze),
            e("payday", "PAYDAY FOCUS", "on the 1st or 15th", "star", .bronze),
            e("weekend_double", "WEEKEND DOUBLE", "both weekend days", "flame", .silver),
            e("perfect_week", "PERFECT WEEK", "every day Mon–Sun", "bolt", .gold),
            e("comeback_kid", "COMEBACK KID", "after a 7+ day break", "target", .silver),
            e("anniversary", "ANNIVERSARY", "~1 year after first", "star", .gold),
            e("holiday_hustle", "HOLIDAY HUSTLE", "Dec 24/25/31", "flame", .silver),
        ]),
        ("STREAKS & HABITS", [
            e("streak_3", "GETTING GOING", "3-day streak", "bolt", .bronze),
            e("streak_7", "FULL WEEK", "7-day streak", "bolt", .silver),
            e("streak_21", "HABIT FORMED", "21-day streak", "bolt", .silver),
            e("streak_30", "MONTHLY", "30-day streak", "flame", .gold),
            e("streak_365", "IRON YEAR", "365-day streak", "skull", .gold),
            e("same_bat_time", "SAME BAT-TIME", "3 days, same hour", "target", .silver),
            e("streak_saver", "STREAK SAVER", "saved it before midnight", "flame", .silver),
            e("phoenix", "PHOENIX", "new streak after a 7+ break", "flame", .silver),
            e("no_zeroes", "NO ZEROES", "5 days in one week", "bolt", .bronze),
            e("double_days", "DOUBLE DAYS", "2+/day for 5 days", "flame", .silver),
        ]),
        ("FOCUS QUALITY", [
            e("laser_mind", "LASER MIND", "a zero-drift session", "target", .bronze),
            e("in_the_zone", "IN THE ZONE", "5 clean in a row", "star", .silver),
            e("untouchable", "UNTOUCHABLE", "20 clean in a row", "star", .gold),
            e("deep_diver", "DEEP DIVER", "30-min unbroken streak", "target", .silver),
            e("rock_solid", "ROCK SOLID", "60-min unbroken streak", "target", .gold),
            e("immovable", "IMMOVABLE", "a day with zero away", "skull", .gold),
            e("nudge_proof", "NUDGE-PROOF", "stayed after a nudge", "bolt", .silver),
            e("bulletproof_week", "BULLETPROOF WEEK", "a week, no early stops", "flame", .silver),
            e("flawless", "FLAWLESS", "100%, 0 drift, 0 pause", "star", .gold),
            e("no_peeking", "NO PEEKING", "10 never-looked-away", "target", .silver),
            e("steady_hands", "STEADY HANDS", "3 clean in a day", "bolt", .silver),
            e("clean_month", "CLEAN MONTH", "a month, no early stops", "flame", .gold),
        ]),
        ("DURATION & MARATHON", [
            e("deep_45", "DEEP 45", "a 45-min session", "flame", .bronze),
            e("deep_90", "DEEP 90", "a 90-min session", "flame", .silver),
            e("iron_focus", "IRON FOCUS", "a 2-hour session", "skull", .gold),
            e("ultra", "ULTRA", "a 3-hour session", "skull", .gold),
            e("sprints", "SPRINTS", "five ≤10-min in a day", "bolt", .silver),
            e("double_feature", "DOUBLE FEATURE", "two 90-min in a day", "flame", .gold),
            e("full_shift", "FULL SHIFT", "8 hours in a day", "skull", .gold),
            e("power_hour", "POWER HOUR", "60 min, zero drift", "target", .silver),
        ]),
        ("COMEBACK", [
            e("back_on_track", "BACK ON TRACK", "return after drifting", "target", .bronze),
            e("persistent", "PERSISTENT", "10 lifetime comebacks", "bolt", .silver),
            e("nine_lives", "NINE LIVES", "away 3× and finished", "target", .silver),
            e("redemption", "REDEMPTION", "day after a 'not done'", "flame", .silver),
            e("quick_bounce", "QUICK BOUNCE", "restart within 5 min", "bolt", .bronze),
            e("round_two", "ROUND TWO", "retry a failed mission", "target", .bronze),
            e("third_charm", "THIRD TIME'S CHARM", "3rd try of the day", "star", .silver),
            e("rise_grind", "RISE & GRIND", "morning after a late one", "sun", .silver),
        ]),
        ("MISSIONS", [
            e("wordsmith", "WORDSMITH", "mission of 5+ words", "star", .bronze),
            e("one_word", "ONE-WORD WONDER", "a one-word mission", "star", .bronze),
            e("blank_canvas", "BLANK CANVAS", "the default mission", "target", .bronze),
            e("creature_habit", "CREATURE OF HABIT", "same mission 5×", "flame", .silver),
            e("renaissance", "RENAISSANCE", "10 distinct missions", "star", .silver),
            e("shipmate", "SHIPMATE", "'ship/finish/done'", "bolt", .bronze),
            e("continuation", "CONTINUATION", "a 'Continue: …' mission", "bolt", .bronze),
            e("polyglot", "POLYGLOT", "a non-Latin mission", "star", .silver),
        ]),
        ("RHYTHM & FUN", [
            e("morning_person", "MORNING PERSON", "5 before noon", "sun", .silver),
            e("evening_person", "EVENING PERSON", "5 after 18:00", "moon", .silver),
            e("warm_up_act", "WARM-UP ACT", "short → 45-min+", "flame", .silver),
            e("cooldown", "COOLDOWN", "end day with <10 min", "moon", .bronze),
            e("bookends", "BOOKENDS", "first & last hour of a day", "sun", .silver),
            e("metronome", "METRONOME", "4 same weekdays in a row", "bolt", .silver),
            e("escalation", "ESCALATION", "3/day, each longer", "flame", .silver),
            e("balanced_diet", "BALANCED DIET", "calm+strict+cinematic/wk", "star", .silver),
            e("speed_demon", "SPEED DEMON", "start within 3s of click", "bolt", .silver),
            e("palindrome", "PALINDROME", "ended at 12:21 etc.", "star", .gold),
            e("round_number", "ROUND NUMBER", "your 100th session", "target", .silver),
            e("overachiever", "OVERACHIEVER", "focus beat the plan", "flame", .silver),
            e("sound_vision", "SOUND & VISION", "20 with sound + camera", "star", .silver),
            e("completionist", "THE COMPLETIONIST", "unlock all 99 others", "skull", .gold),
        ]),
    ]

    static let all: [CatalogEntry] = families.flatMap { $0.1 }
    static var total: Int { all.count }

    private static func e(_ id: String, _ t: String, _ d: String, _ ic: String, _ tier: BadgeTier) -> CatalogEntry {
        CatalogEntry(id: id, title: t, detail: d, icon: ic, tier: tier)
    }
}

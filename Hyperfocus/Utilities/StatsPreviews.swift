// StatsPreviews.swift — DEBUG-only mockup (HF_STATS_PREVIEW=1) of the Statistics window:
// tab 1 OVERVIEW (focus stats + weekly chart), tab 2 ACHIEVEMENTS (badge grid to ~100).
// Access in prod: menu bar → "Statistics…". Preview-before-prod; approve the layout, then it ships.

#if DEBUG
import SwiftUI
import AppKit

// MARK: Achievement catalog design (~100 across 8 families) — the mockup shows a representative slice

private struct BadgeSpec: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: [String]
    let color: Color
    let unlocked: Bool
    var progress: Double? = nil   // 0…1 for in-progress badges
}

private enum Catalog {
    // Representative sample; the full set fans each family out to its milestones (→ ~100).
    static let families: [(String, [BadgeSpec])] = [
        ("FIRSTS", [
            b("first_session", "FIRST LIGHT", "your first session", PixelIcon.target, FD.lime, true),
            b("first_hour", "ONE HOUR IN", "60 focused minutes", PixelIcon.flame, FD.lime, true),
            b("first_week", "WEEK ONE", "7 days with the app", PixelIcon.sun, FD.amber, false, 0.57),
        ]),
        ("VOLUME · total focus hours", [
            b("hours_1", "GETTING WARM", "1 hour total", PixelIcon.flame, FD.lime, true),
            b("hours_10", "REGULAR", "10 hours total", PixelIcon.flame, FD.lime, true),
            b("hours_50", "DEDICATED", "50 hours total", PixelIcon.flame, FD.amber, false, 0.36),
            b("hours_100", "CENTURION", "100 hours total", PixelIcon.flame, FD.amber, false, 0.18),
            b("hours_500", "MASTER", "500 hours total", PixelIcon.skull, FD.redLED, false, 0.036),
        ]),
        ("STREAKS · days in a row", [
            b("streak_3", "STREAK ×3", "3 days", PixelIcon.bolt, FD.lime, true),
            b("streak_7", "STREAK ×7", "a full week", PixelIcon.bolt, FD.lime, true),
            b("streak_30", "STREAK ×30", "a month", PixelIcon.bolt, FD.amber, false, 0.23),
            b("streak_100", "UNBROKEN", "100 days", PixelIcon.bolt, FD.redLED, false, 0.07),
        ]),
        ("QUALITY · zero-drift", [
            b("laser_1", "LASER MIND", "a drift-free session", PixelIcon.target, FD.lime, true),
            b("laser_10", "LASER ×10", "10 drift-free", PixelIcon.target, FD.amber, false, 0.6),
            b("laser_row5", "IN THE ZONE", "5 clean in a row", PixelIcon.star, FD.amber, false, 0.4),
        ]),
        ("RHYTHM · time of day", [
            b("early_bird", "EARLY BIRD", "before 7am", PixelIcon.sun, FD.amber, true),
            b("night_owl", "NIGHT OWL", "after midnight", PixelIcon.moon, Color(red: 0.24, green: 0.90, blue: 0.88), true),
            b("lunch", "LUNCH FOCUS", "12–14h session", PixelIcon.sun, FD.lime, false),
            b("weekend", "WEEKEND WARRIOR", "sat+sun focus", PixelIcon.star, FD.amber, false),
        ]),
        ("MARATHON · single session", [
            b("long_45", "DEEP 45", "45-min session", PixelIcon.flame, FD.lime, true),
            b("long_90", "DEEP 90", "90-min session", PixelIcon.flame, FD.amber, false, 0.5),
            b("long_120", "IRON FOCUS", "2-hour session", PixelIcon.skull, FD.redLED, false),
        ]),
        ("COMEBACK · resilience", [
            b("comeback_1", "BACK ON TRACK", "returned after drifting", PixelIcon.target, FD.lime, true),
            b("comeback_10", "PERSISTENT", "10 comebacks", PixelIcon.bolt, FD.amber, false, 0.7),
        ]),
        ("DAY · volume in one day", [
            b("day_3", "TRIPLE", "3 sessions in a day", PixelIcon.star, FD.lime, true),
            b("day_5", "FIVE ALIVE", "5 in a day", PixelIcon.star, FD.amber, false, 0.6),
            b("day_marathon", "ALL-DAYER", "4h in one day", PixelIcon.flame, FD.redLED, false, 0.3),
        ]),
    ]
    static func b(_ id: String, _ t: String, _ d: String, _ ic: [String], _ c: Color,
                  _ u: Bool, _ p: Double? = nil) -> BadgeSpec {
        BadgeSpec(id: id, title: t, detail: d, icon: ic, color: c, unlocked: u, progress: p)
    }
    static var total: Int { 100 }
    static var unlockedCount: Int { families.flatMap { $0.1 }.filter { $0.unlocked }.count }
}

// MARK: The window

struct StatsWindowView: View {
    @State private var tab: Int
    private let scroll: Bool
    init(initialTab: Int = 0, scroll: Bool = true) {
        _tab = State(initialValue: initialTab); self.scroll = scroll
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            if tab == 0 { OverviewTab(scroll: scroll) } else { AchievementsTab(scroll: scroll) }
        }
        .frame(width: 560, height: 620)
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
                Circle().fill(FD.lime.opacity(0.10)).frame(width: 200, height: 200)
                    .blur(radius: 80).offset(x: -50, y: -60)
            }
        )
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle().fill(FD.lime).frame(width: 8, height: 8).shadow(color: FD.lime, radius: 5)
            Text("STATISTICS").font(FD.matrix(18)).foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 14)
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            tabButton("OVERVIEW", 0)
            tabButton("ACHIEVEMENTS", 1)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.bottom, 12)
    }

    private func tabButton(_ title: String, _ i: Int) -> some View {
        let on = tab == i
        return Button { tab = i } label: {
            Text(title).font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundStyle(on ? .black : FD.label)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(on ? AnyShapeStyle(FD.limeGradient)
                                              : AnyShapeStyle(Color.black.opacity(0.3))))
        }
        .buttonStyle(.plain)
    }
}

// MARK: Overview tab

private struct OverviewTab: View {
    var scroll = true
    // Sample data.
    private let weekly: [Double] = [42, 75, 0, 90, 60, 25, 110]   // minutes per weekday
    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let content = VStack(spacing: 16) {
            HStack(spacing: 12) {
                stat("TOTAL FOCUS", "37h 12m", PixelIcon.flame, FD.lime)
                stat("CURRENT STREAK", "5 days", PixelIcon.bolt, FD.amber)
            }
            HStack(spacing: 12) {
                stat("LONGEST STREAK", "12 days", PixelIcon.bolt, FD.lime)
                stat("SESSIONS", "128", PixelIcon.target, FD.lime)
            }
            weeklyChart
            HStack(spacing: 12) {
                stat("BEST HOUR", "10:00", PixelIcon.sun, FD.amber)
                stat("LASER RATE", "64%", PixelIcon.star, FD.lime)
            }
        }
        .padding(20)
        if scroll { ScrollView { content } } else { VStack { content; Spacer() } }
    }

    private func stat(_ label: String, _ value: String, _ icon: [String], _ color: Color) -> some View {
        FDInset {
            HStack(spacing: 12) {
                PixelIcon(pattern: icon, color: color, pixel: 2.4).frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value).font(FD.matrix(20)).foregroundStyle(.white)
                    Text(label).font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(FD.label)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var weeklyChart: some View {
        FDInset {
            VStack(alignment: .leading, spacing: 10) {
                Text("THIS WEEK").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(FD.label)
                let maxV = max(weekly.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(weekly[i] > 0 ? AnyShapeStyle(FD.limeGradient)
                                                    : AnyShapeStyle(Color.white.opacity(0.08)))
                                .frame(height: max(3, CGFloat(weekly[i] / maxV) * 90))
                                .shadow(color: weekly[i] > 0 ? FD.lime.opacity(0.5) : .clear, radius: 5)
                            Text(days[i]).font(.system(size: 9, weight: .bold)).foregroundStyle(FD.label)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110, alignment: .bottom)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: Achievements tab

private struct AchievementsTab: View {
    var scroll = true
    private let cols = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(Catalog.unlockedCount) / \(Catalog.total) unlocked")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(FD.lime)
                Spacer()
                Capsule().fill(.white.opacity(0.08)).frame(width: 120, height: 5)
                    .overlay(alignment: .leading) {
                        Capsule().fill(FD.limeGradient)
                            .frame(width: 120 * Double(Catalog.unlockedCount) / Double(Catalog.total), height: 5)
                    }
            }
            ForEach(Catalog.families, id: \.0) { family in
                Text(family.0).font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(FD.label)
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(family.1) { badge in badgeCell(badge) }
                }
            }
        }
        .padding(20)
        if scroll { ScrollView { content } } else { VStack { content; Spacer() } }
    }

    private func badgeCell(_ b: BadgeSpec) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(b.unlocked ? Color.black.opacity(0.4) : Color.black.opacity(0.2))
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(b.unlocked ? b.color.opacity(0.5) : .white.opacity(0.05), lineWidth: 1)
                PixelIcon(pattern: b.icon, color: b.unlocked ? b.color : .white.opacity(0.18), pixel: 2.6)
                    .shadow(color: b.unlocked ? b.color.opacity(0.6) : .clear, radius: 8)
                if let p = b.progress, !b.unlocked {
                    VStack { Spacer()
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.08)).frame(height: 3)
                                Capsule().fill(b.color.opacity(0.7)).frame(width: g.size.width * p, height: 3)
                            }
                        }
                        .frame(height: 3).padding(.horizontal, 12).padding(.bottom, 8)
                    }
                }
            }
            .frame(width: 96, height: 76)
            Text(b.title).font(.system(size: 9, weight: .bold))
                .foregroundStyle(b.unlocked ? .white : FD.label)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(b.detail).font(.system(size: 8)).foregroundStyle(FD.label)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

@MainActor
enum StatsPreviewWindow {
    private static var window: NSWindow?
    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 560, height: 620),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Statistics (mockup)"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: StatsWindowView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif

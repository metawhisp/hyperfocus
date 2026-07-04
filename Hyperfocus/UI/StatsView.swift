// StatsView.swift — the Statistics window (canon #41): OVERVIEW (live focus stats + weekly chart)
// and ACHIEVEMENTS (the 100-entry catalog; unlocked ones from AchievementsStore light up).
// Opened from the menu bar → "Statistics…".

import SwiftUI

struct StatsView: View {
    let stats: FocusStats
    let unlockedIDs: Set<String>
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            if tab == 0 { OverviewTab(stats: stats) }
            else { AchievementsTab(unlockedIDs: unlockedIDs) }
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

// MARK: Overview

private struct OverviewTab: View {
    let stats: FocusStats
    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    stat("TOTAL FOCUS", stats.totalFocusText, "flame", FD.lime)
                    stat("CURRENT STREAK", streakText(stats.currentStreakDays), "bolt", FD.amber)
                }
                HStack(spacing: 12) {
                    stat("LONGEST STREAK", streakText(stats.longestStreakDays), "bolt", FD.lime)
                    stat("SESSIONS", "\(stats.sessionCount)", "target", FD.lime)
                }
                weeklyChart
                HStack(spacing: 12) {
                    stat("BEST HOUR", stats.bestHourText, "sun", FD.amber)
                    stat("LASER RATE", stats.laserRateText, "star", FD.lime)
                }
            }
            .padding(20)
        }
    }

    private func streakText(_ d: Int) -> String { d == 1 ? "1 day" : "\(d) days" }

    private func stat(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        FDInset {
            HStack(spacing: 12) {
                PixelIcon(pattern: PixelIcon.pattern(named: icon), color: color, pixel: 2.4).frame(width: 26)
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
                let maxV = max(stats.weeklyMinutes.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(stats.weeklyMinutes[i] > 0 ? AnyShapeStyle(FD.limeGradient)
                                                                 : AnyShapeStyle(Color.white.opacity(0.08)))
                                .frame(height: max(3, CGFloat(stats.weeklyMinutes[i] / maxV) * 90))
                                .shadow(color: stats.weeklyMinutes[i] > 0 ? FD.lime.opacity(0.5) : .clear, radius: 5)
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

// MARK: Achievements

private struct AchievementsTab: View {
    let unlockedIDs: Set<String>
    private let cols = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(unlockedIDs.count) / \(AchievementCatalog.total) unlocked")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(FD.lime)
                    Spacer()
                    Capsule().fill(.white.opacity(0.08)).frame(width: 120, height: 5)
                        .overlay(alignment: .leading) {
                            Capsule().fill(FD.limeGradient)
                                .frame(width: 120 * Double(unlockedIDs.count) / Double(AchievementCatalog.total), height: 5)
                        }
                }
                ForEach(AchievementCatalog.families, id: \.0) { family in
                    Text(family.0).font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(FD.label)
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(family.1) { entry in badgeCell(entry) }
                    }
                }
            }
            .padding(20)
        }
    }

    private func badgeCell(_ e: CatalogEntry) -> some View {
        let on = unlockedIDs.contains(e.id)
        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(on ? 0.4 : 0.2))
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(on ? e.tier.color.opacity(0.5) : .white.opacity(0.05), lineWidth: 1)
                PixelIcon(pattern: PixelIcon.pattern(named: e.icon),
                          color: on ? e.tier.color : .white.opacity(0.18), pixel: 2.6)
                    .shadow(color: on ? e.tier.color.opacity(0.6) : .clear, radius: 8)
            }
            .frame(width: 96, height: 76)
            Text(e.title).font(.system(size: 9, weight: .bold))
                .foregroundStyle(on ? .white : FD.label)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(e.detail).font(.system(size: 8)).foregroundStyle(FD.label)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

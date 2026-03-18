import Charts
import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                HStack(spacing: 18) {
                    summaryTile(
                        title: "Best Streak",
                        value: model.bestStreak == 1 ? "1 day" : "\(model.bestStreak) days",
                        caption: "Days at 80% of goal or better"
                    )
                    summaryTile(
                        title: "Good Days",
                        value: "\(model.goodStudyDaysCount)",
                        caption: "Last 30 days"
                    )
                    summaryTile(
                        title: "Needs Rescue",
                        value: "\(model.badStudyDaysCount)",
                        caption: "Light study days below 40%"
                    )
                }

                studyTrendCard
                weekdayPatternCard
            }
            .padding(24)
        }
        .navigationTitle("Study Insights")
        .commandCenterBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study Insights")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(CommandCenterTheme.title)

            Text(insightNarrative)
                .font(.title3)
                .foregroundStyle(CommandCenterTheme.body)
        }
    }

    private var studyTrendCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("30-Day Trend", systemImage: "chart.bar.fill")
                .font(.headline)

            Chart(model.snapshot.recentDailyHistory, id: \.dayStart) { day in
                BarMark(
                    x: .value("Day", day.dayStart, unit: .day),
                    y: .value("Hours", day.totalHours)
                )
                .cornerRadius(6)
                .foregroundStyle(studyColor(for: day))

                RuleMark(y: .value("Target", Double(day.targetMinutes) / 60.0))
                    .foregroundStyle(Color.white.opacity(0.20))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 4))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 280)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private var weekdayPatternCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Weekday Pattern", systemImage: "calendar.badge.clock")
                .font(.headline)

            Chart(model.weekdayAverages) { item in
                BarMark(
                    x: .value("Weekday", item.label),
                    y: .value("Average Hours", item.averageHours)
                )
                .cornerRadius(8)
                .foregroundStyle(weekdayColor(for: item))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 240)

            HStack(spacing: 14) {
                insightChip(
                    title: "Strongest day",
                    value: model.bestWeekday.map { "\($0.label) • \(String(format: "%.1f", $0.averageHours)) hrs" } ?? "Not enough data"
                )
                insightChip(
                    title: "Weakest day",
                    value: model.weakestWeekday.map { "\($0.label) • \(String(format: "%.1f", $0.averageHours)) hrs" } ?? "Not enough data"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private var insightNarrative: String {
        let best = model.bestWeekday?.label ?? "your strongest weekday"
        let weakest = model.weakestWeekday?.label ?? "your lightest weekday"
        return "Use this screen to spot the rhythm behind your study hours. Right now, \(best) looks strongest while \(weakest) is the easiest day to reinforce."
    }

    private func summaryTile(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(caption)
                .font(.callout)
                .foregroundStyle(CommandCenterTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private func insightChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(CommandCenterTheme.muted)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CommandCenterTheme.cardAlt)
        )
    }

    private func studyColor(for day: FocusDaySummary) -> Color {
        let ratio = model.completionRatio(for: day)
        if ratio >= 1 {
            return Color(red: 0.19, green: 0.58, blue: 0.35)
        }
        if ratio >= 0.6 {
            return Color(red: 0.85, green: 0.60, blue: 0.18)
        }
        if ratio > 0 {
            return Color(red: 0.90, green: 0.46, blue: 0.47)
        }
        return Color(red: 0.72, green: 0.72, blue: 0.75)
    }

    private func weekdayColor(for item: WeekdayStudyAverage) -> Color {
        let maxHours = model.weekdayAverages.map(\.averageHours).max() ?? 1
        guard maxHours > 0 else { return Color.gray }
        let ratio = item.averageHours / maxHours

        if ratio > 0.85 {
            return Color(red: 0.19, green: 0.58, blue: 0.35)
        }
        if ratio > 0.5 {
            return Color(red: 0.20, green: 0.45, blue: 0.74)
        }
        return Color(red: 0.90, green: 0.46, blue: 0.47)
    }
}

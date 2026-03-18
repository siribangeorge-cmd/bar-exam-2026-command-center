import Charts
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                HStack(alignment: .top, spacing: 18) {
                    countdownCard
                    dailyTargetCard
                    syllabusCard
                }

                HStack(alignment: .top, spacing: 18) {
                    pomodoroCard
                    examWeekCard
                }

                studyPulseCard
            }
            .padding(24)
        }
        .navigationTitle("Bar Command Center")
        .commandCenterBackground()
        .onReceive(ticker) { _ in
            model.handleTick()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bar Exam 2026")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(CommandCenterTheme.warmAccent)
                .textCase(.uppercase)

            Text("Command Center")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(CommandCenterTheme.title)

            Text("Track your syllabus, guard your time, and make each study day visible before September 6, 2026.")
                .font(.title3)
                .foregroundStyle(CommandCenterTheme.body)
        }
    }

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Countdown", systemImage: "hourglass.tophalf.filled")
                .font(.headline)

            Text(model.countdownLabel)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(CommandCenterTheme.countdown)

            Text(model.countdownDetail)
                .font(.subheadline)
                .foregroundStyle(CommandCenterTheme.muted)

            Divider()

            Text("First exam block starts at 8:00 AM, Manila time.")
                .font(.callout)
                .foregroundStyle(CommandCenterTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private var dailyTargetCard: some View {
        HStack(spacing: 18) {
            ProgressRing(
                progress: model.focusCompletionRatio,
                label: model.todayHoursText,
                tint: Color(red: 0.22, green: 0.77, blue: 0.57)
            )
            .frame(width: 124, height: 124)

            VStack(alignment: .leading, spacing: 10) {
                Label("Today's Study Target", systemImage: "scope")
                    .font(.headline)

                Text(model.allTimeStudyHoursText)
                    .font(.title3.weight(.semibold))

                Text("Good days: \(model.goodStudyDaysCount)  •  Needs rescue: \(model.badStudyDaysCount)")
                    .font(.callout)
                    .foregroundStyle(CommandCenterTheme.muted)

                Text(model.bestStreak == 1 ? "Best streak: 1 day" : "Best streak: \(model.bestStreak) days")
                    .font(.callout)
                    .foregroundStyle(CommandCenterTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private var syllabusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Syllabus Coverage", systemImage: "highlighter")
                .font(.headline)

            Text("\(Int(model.syllabusCompletionRatio * 100))% mapped")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(CommandCenterTheme.accent)

            ProgressView(value: model.syllabusCompletionRatio)
                .tint(CommandCenterTheme.accent)

            Text("\(model.examReadySectionsCount) sections marked exam-ready out of \(SyllabusCatalog.totalSections).")
                .font(.callout)
                .foregroundStyle(CommandCenterTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private var pomodoroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Pomodoro Timer", systemImage: "timer")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text(model.timerState.phase.title)
                    .font(.title3.weight(.semibold))
                Text(model.remainingTimeText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(model.timerState.phase.accentDescription)
                    .font(.callout)
                    .foregroundStyle(CommandCenterTheme.muted)
                Text(model.currentCycleText)
                    .font(.callout)
                    .foregroundStyle(CommandCenterTheme.muted)
            }

            HStack(spacing: 12) {
                Button(model.timerState.isRunning ? "Pause" : "Start") {
                    model.toggleTimer()
                }
                .buttonStyle(.borderedProminent)
                .tint(CommandCenterTheme.warmAccent)

                Button("Skip") {
                    model.skipCurrentPhase()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                miniMetric(title: "Focus", value: "\(model.settings.focusMinutes) min")
                miniMetric(title: "Short break", value: "\(model.settings.shortBreakMinutes) min")
                miniMetric(title: "Long break", value: "\(model.settings.longBreakMinutes) min")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private var examWeekCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Exam Week Map", systemImage: "calendar")
                .font(.headline)

            ForEach(model.examSchedule) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.label)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(CommandCenterTheme.warmAccent)
                        Spacer()
                        Text(item.weight)
                            .font(.subheadline.weight(.semibold))
                    }

                    Text(item.subject)
                        .font(.body.weight(.semibold))
                    Text("\(item.dateLabel) • \(item.sessionLabel)")
                        .font(.callout)
                        .foregroundStyle(CommandCenterTheme.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(CommandCenterTheme.cardAlt)
                )
            }
        }
        .frame(width: 380, alignment: .leading)
        .commandCenterCard()
    }

    private var studyPulseCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Study Pulse", systemImage: "chart.bar.xaxis")
                        .font(.headline)
                    Text("Last 14 days of recorded focus time, with your daily target shown as the guide rail.")
                        .font(.callout)
                        .foregroundStyle(CommandCenterTheme.muted)
                }

                Spacer()

                if let bestDay = model.bestStudyDay {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Best day")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CommandCenterTheme.muted)
                        Text(bestDay.dayStart.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.subheadline.weight(.semibold))
                        Text(String(format: "%.1f hrs", bestDay.totalHours))
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }

            Chart(recentDays, id: \.dayStart) { day in
                BarMark(
                    x: .value("Day", day.dayStart, unit: .day),
                    y: .value("Hours", day.totalHours)
                )
                .cornerRadius(8)
                .foregroundStyle(studyColor(for: day))

                RuleMark(y: .value("Target", Double(day.targetMinutes) / 60.0))
                    .foregroundStyle(Color.white.opacity(0.20))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 250)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .commandCenterCard()
    }

    private var recentDays: [FocusDaySummary] {
        Array(model.snapshot.recentDailyHistory.suffix(14))
    }

    private func miniMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(CommandCenterTheme.muted)
            Text(value)
                .font(.headline.monospacedDigit())
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
}

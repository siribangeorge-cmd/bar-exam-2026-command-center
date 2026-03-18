import Foundation

public struct FocusAnalytics: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func progressSnapshot(
        sessions: [FocusSession],
        for date: Date,
        target: StudyTarget,
        recentHistoryDays: Int = 14
    ) -> FocusProgressSnapshot {
        let today = daySummary(sessions: sessions, for: date, target: target)
        let week = weekSummary(sessions: sessions, containing: date, target: target)
        let month = monthSummary(sessions: sessions, containing: date, target: target)
        let history = recentDailyHistory(sessions: sessions, endingOn: date, days: recentHistoryDays, target: target)

        return FocusProgressSnapshot(
            today: today,
            week: week,
            month: month,
            appLockState: AppLockState(completedMinutesToday: today.totalMinutes, targetMinutes: target.dailyMinutes),
            recentDailyHistory: history
        )
    }

    public func daySummary(
        sessions: [FocusSession],
        for date: Date,
        target: StudyTarget
    ) -> FocusDaySummary {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let totalMinutes = focusMinutes(sessions: sessions, in: DateInterval(start: start, end: end))
        return FocusDaySummary(dayStart: start, totalMinutes: totalMinutes, targetMinutes: target.dailyMinutes)
    }

    public func recentDailyHistory(
        sessions: [FocusSession],
        endingOn date: Date,
        days: Int,
        target: StudyTarget
    ) -> [FocusDaySummary] {
        guard days > 0 else { return [] }

        let endDay = calendar.startOfDay(for: date)
        return (0..<days).compactMap { offset in
            guard let currentDay = calendar.date(byAdding: .day, value: -(days - 1 - offset), to: endDay) else {
                return nil
            }

            return daySummary(sessions: sessions, for: currentDay, target: target)
        }
    }

    public func weekSummary(
        sessions: [FocusSession],
        containing date: Date,
        target: StudyTarget
    ) -> FocusPeriodSummary {
        let interval = calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 0)
        let totalMinutes = focusMinutes(sessions: sessions, in: interval)
        let targetMinutes = target.dailyMinutes * activeDays(in: interval, component: .day)
        return FocusPeriodSummary(interval: interval, totalMinutes: totalMinutes, targetMinutes: targetMinutes)
    }

    public func monthSummary(
        sessions: [FocusSession],
        containing date: Date,
        target: StudyTarget
    ) -> FocusPeriodSummary {
        let interval = calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 0)
        let totalMinutes = focusMinutes(sessions: sessions, in: interval)
        let targetMinutes = target.dailyMinutes * activeDays(in: interval, component: .day)
        return FocusPeriodSummary(interval: interval, totalMinutes: totalMinutes, targetMinutes: targetMinutes)
    }

    public func focusMinutes(
        sessions: [FocusSession],
        in interval: DateInterval
    ) -> Int {
        sessions.reduce(into: 0) { total, session in
            total += overlappingMinutes(for: session, in: interval)
        }
    }

    private func overlappingMinutes(for session: FocusSession, in interval: DateInterval) -> Int {
        let overlapStart = max(session.startAt, interval.start)
        let overlapEnd = min(session.endAt, interval.end)

        guard overlapEnd > overlapStart else { return 0 }
        return Int(overlapEnd.timeIntervalSince(overlapStart) / 60)
    }

    private func activeDays(in interval: DateInterval, component: Calendar.Component) -> Int {
        let count = calendar.dateComponents([component], from: interval.start, to: interval.end).value(for: component) ?? 0
        return max(count, 0)
    }
}

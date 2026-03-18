import Foundation
import Testing
@testable import FocusLockCore

struct FocusAnalyticsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    @Test func lockStateStaysActiveUntilDailyTargetIsMet() async throws {
        let sessions = [
            FocusSession(
                startAt: date(2026, 3, 18, 9, 0),
                endAt: date(2026, 3, 18, 11, 30)
            )
        ]
        let analytics = FocusAnalytics(calendar: calendar)

        let snapshot = analytics.progressSnapshot(
            sessions: sessions,
            for: date(2026, 3, 18, 12, 0),
            target: StudyTarget(hoursPerDay: 8)
        )

        #expect(snapshot.today.totalMinutes == 150)
        #expect(snapshot.appLockState.isUnlocked == false)
        #expect(snapshot.appLockState.remainingMinutes == 330)
    }

    @Test func lockStateUnlocksOnceTargetIsReached() async throws {
        let sessions = [
            FocusSession(
                startAt: date(2026, 3, 18, 8, 0),
                endAt: date(2026, 3, 18, 12, 0)
            ),
            FocusSession(
                startAt: date(2026, 3, 18, 13, 0),
                endAt: date(2026, 3, 18, 17, 0)
            ),
        ]
        let analytics = FocusAnalytics(calendar: calendar)

        let snapshot = analytics.progressSnapshot(
            sessions: sessions,
            for: date(2026, 3, 18, 17, 0),
            target: StudyTarget(hoursPerDay: 8)
        )

        #expect(snapshot.today.totalMinutes == 480)
        #expect(snapshot.appLockState.isUnlocked)
        #expect(snapshot.appLockState.remainingMinutes == 0)
    }

    @Test func dailyHistorySplitsSessionsAcrossMidnight() async throws {
        let sessions = [
            FocusSession(
                startAt: date(2026, 3, 17, 23, 30),
                endAt: date(2026, 3, 18, 1, 0)
            )
        ]
        let analytics = FocusAnalytics(calendar: calendar)

        let history = analytics.recentDailyHistory(
            sessions: sessions,
            endingOn: date(2026, 3, 18, 8, 0),
            days: 2,
            target: StudyTarget(hoursPerDay: 8)
        )

        #expect(history.count == 2)
        #expect(history[0].totalMinutes == 30)
        #expect(history[1].totalMinutes == 60)
    }

    @Test func weekAndMonthSummariesAccumulateAcrossMultipleDays() async throws {
        let sessions = [
            FocusSession(
                startAt: date(2026, 3, 16, 9, 0),
                endAt: date(2026, 3, 16, 11, 0)
            ),
            FocusSession(
                startAt: date(2026, 3, 17, 14, 0),
                endAt: date(2026, 3, 17, 17, 0)
            ),
            FocusSession(
                startAt: date(2026, 3, 18, 8, 0),
                endAt: date(2026, 3, 18, 10, 30)
            ),
            FocusSession(
                startAt: date(2026, 3, 2, 8, 0),
                endAt: date(2026, 3, 2, 9, 0)
            ),
        ]
        let analytics = FocusAnalytics(calendar: calendar)

        let snapshot = analytics.progressSnapshot(
            sessions: sessions,
            for: date(2026, 3, 18, 12, 0),
            target: StudyTarget(hoursPerDay: 8)
        )

        #expect(snapshot.week.totalMinutes == 450)
        #expect(snapshot.month.totalMinutes == 510)
        #expect(snapshot.recentDailyHistory.last?.totalMinutes == 150)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )

        return calendar.date(from: components) ?? .distantPast
    }
}

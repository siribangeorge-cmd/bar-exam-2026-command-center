import Foundation

public struct StudyTarget: Sendable, Codable, Hashable {
    public let dailyMinutes: Int

    public init(hoursPerDay: Int) {
        self.dailyMinutes = max(hoursPerDay, 0) * 60
    }

    public init(dailyMinutes: Int) {
        self.dailyMinutes = max(dailyMinutes, 0)
    }
}

public struct FocusSession: Identifiable, Sendable, Codable, Hashable {
    public let id: UUID
    public let startAt: Date
    public let endAt: Date

    public init(id: UUID = UUID(), startAt: Date, endAt: Date) {
        self.id = id
        self.startAt = startAt
        self.endAt = max(startAt, endAt)
    }

    public var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }
}

public struct FocusDaySummary: Sendable, Codable, Hashable {
    public let dayStart: Date
    public let totalMinutes: Int
    public let targetMinutes: Int

    public init(dayStart: Date, totalMinutes: Int, targetMinutes: Int) {
        self.dayStart = dayStart
        self.totalMinutes = max(totalMinutes, 0)
        self.targetMinutes = max(targetMinutes, 0)
    }

    public var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    public var isTargetMet: Bool {
        totalMinutes >= targetMinutes
    }

    public var remainingMinutes: Int {
        max(targetMinutes - totalMinutes, 0)
    }
}

public struct FocusPeriodSummary: Sendable, Codable, Hashable {
    public let interval: DateInterval
    public let totalMinutes: Int
    public let targetMinutes: Int

    public init(interval: DateInterval, totalMinutes: Int, targetMinutes: Int) {
        self.interval = interval
        self.totalMinutes = max(totalMinutes, 0)
        self.targetMinutes = max(targetMinutes, 0)
    }

    public var completionRatio: Double {
        guard targetMinutes > 0 else { return totalMinutes > 0 ? 1 : 0 }
        return min(Double(totalMinutes) / Double(targetMinutes), 1)
    }
}

public struct AppLockState: Sendable, Codable, Hashable {
    public let completedMinutesToday: Int
    public let targetMinutes: Int

    public init(completedMinutesToday: Int, targetMinutes: Int) {
        self.completedMinutesToday = max(completedMinutesToday, 0)
        self.targetMinutes = max(targetMinutes, 0)
    }

    public var isUnlocked: Bool {
        completedMinutesToday >= targetMinutes
    }

    public var remainingMinutes: Int {
        max(targetMinutes - completedMinutesToday, 0)
    }
}

public struct FocusProgressSnapshot: Sendable, Codable, Hashable {
    public let today: FocusDaySummary
    public let week: FocusPeriodSummary
    public let month: FocusPeriodSummary
    public let appLockState: AppLockState
    public let recentDailyHistory: [FocusDaySummary]

    public init(
        today: FocusDaySummary,
        week: FocusPeriodSummary,
        month: FocusPeriodSummary,
        appLockState: AppLockState,
        recentDailyHistory: [FocusDaySummary]
    ) {
        self.today = today
        self.week = week
        self.month = month
        self.appLockState = appLockState
        self.recentDailyHistory = recentDailyHistory
    }
}

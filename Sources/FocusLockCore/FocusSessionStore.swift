import Foundation

public actor FocusSessionStore {
    private var sessions: [FocusSession]
    private let analytics: FocusAnalytics

    public init(
        sessions: [FocusSession] = [],
        analytics: FocusAnalytics = FocusAnalytics()
    ) {
        self.sessions = sessions.sorted(by: { $0.startAt < $1.startAt })
        self.analytics = analytics
    }

    public func record(session: FocusSession) {
        sessions.append(session)
        sessions.sort(by: { $0.startAt < $1.startAt })
    }

    public func allSessions() -> [FocusSession] {
        sessions
    }

    public func progressSnapshot(
        for date: Date,
        target: StudyTarget,
        recentHistoryDays: Int = 14
    ) -> FocusProgressSnapshot {
        analytics.progressSnapshot(
            sessions: sessions,
            for: date,
            target: target,
            recentHistoryDays: recentHistoryDays
        )
    }
}

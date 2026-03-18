import Foundation

enum PomodoroPhase: String, Codable, CaseIterable, Sendable {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    var accentDescription: String {
        switch self {
        case .focus:
            return "Study now. Social apps stay locked until your goal is done."
        case .shortBreak:
            return "Take a quick reset."
        case .longBreak:
            return "You earned a longer break."
        }
    }
}

struct PomodoroTimerState: Codable, Sendable, Equatable {
    var phase: PomodoroPhase
    var phaseStartedAt: Date?
    var phaseEndsAt: Date?
    var pausedRemainingSeconds: Int?
    var completedFocusCycles: Int

    static func makeReadyFocusState(using settings: StoredAppSettings) -> PomodoroTimerState {
        PomodoroTimerState(
            phase: .focus,
            phaseStartedAt: nil,
            phaseEndsAt: nil,
            pausedRemainingSeconds: settings.focusMinutes * 60,
            completedFocusCycles: 0
        )
    }

    var isRunning: Bool {
        phaseStartedAt != nil && phaseEndsAt != nil
    }

    func remainingSeconds(now: Date, settings: StoredAppSettings) -> Int {
        if let phaseEndsAt {
            return max(Int(phaseEndsAt.timeIntervalSince(now)), 0)
        }

        if let pausedRemainingSeconds {
            return max(pausedRemainingSeconds, 0)
        }

        return defaultSeconds(using: settings)
    }

    mutating func start(now: Date, settings: StoredAppSettings) {
        guard !isRunning else { return }
        let seconds = max(pausedRemainingSeconds ?? defaultSeconds(using: settings), 1)
        phaseStartedAt = now
        phaseEndsAt = now.addingTimeInterval(TimeInterval(seconds))
        pausedRemainingSeconds = nil
    }

    mutating func pause(now: Date, settings: StoredAppSettings) {
        guard let phaseEndsAt else { return }
        pausedRemainingSeconds = max(Int(phaseEndsAt.timeIntervalSince(now)), 0)
        self.phaseEndsAt = nil
        phaseStartedAt = nil

        if pausedRemainingSeconds == 0 {
            pausedRemainingSeconds = defaultSeconds(using: settings)
        }
    }

    mutating func skip(using settings: StoredAppSettings) {
        moveToNextPhase(afterRecordingFocusAt: nil, settings: settings)
    }

    mutating func consumeElapsedTimer(now: Date, settings: StoredAppSettings) -> FocusSession? {
        guard
            let startedAt = phaseStartedAt,
            let phaseEndsAt,
            now >= phaseEndsAt
        else {
            return nil
        }

        let completedSession: FocusSession?
        if phase == .focus {
            completedSession = FocusSession(startAt: startedAt, endAt: phaseEndsAt)
        } else {
            completedSession = nil
        }

        moveToNextPhase(afterRecordingFocusAt: phaseEndsAt, settings: settings)
        return completedSession
    }

    private mutating func moveToNextPhase(afterRecordingFocusAt completedAt: Date?, settings: StoredAppSettings) {
        switch phase {
        case .focus:
            completedFocusCycles += 1
            let shouldUseLongBreak = completedFocusCycles.isMultiple(of: settings.sessionsBeforeLongBreak)
            phase = shouldUseLongBreak ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            phase = .focus
        }

        phaseStartedAt = nil
        phaseEndsAt = nil
        pausedRemainingSeconds = defaultSeconds(using: settings)
    }

    private func defaultSeconds(using settings: StoredAppSettings) -> Int {
        switch phase {
        case .focus:
            return settings.focusMinutes * 60
        case .shortBreak:
            return settings.shortBreakMinutes * 60
        case .longBreak:
            return settings.longBreakMinutes * 60
        }
    }
}

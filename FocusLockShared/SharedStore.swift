import Foundation

enum SharedStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func loadSettings() -> StoredAppSettings {
        guard
            let data = AppGroup.defaults.data(forKey: AppGroup.Key.settings),
            let settings = try? decoder.decode(StoredAppSettings.self, from: data)
        else {
            return .default
        }

        return settings.normalized()
    }

    static func saveSettings(_ settings: StoredAppSettings) {
        guard let data = try? encoder.encode(settings.normalized()) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.settings)
    }

    static func loadSessions() -> [FocusSession] {
        guard
            let data = AppGroup.defaults.data(forKey: AppGroup.Key.sessions),
            let sessions = try? decoder.decode([FocusSession].self, from: data)
        else {
            return []
        }

        return sessions.sorted(by: { $0.startAt < $1.startAt })
    }

    static func saveSessions(_ sessions: [FocusSession]) {
        guard let data = try? encoder.encode(sessions.sorted(by: { $0.startAt < $1.startAt })) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.sessions)
    }

    static func appendSession(_ session: FocusSession) {
        var sessions = loadSessions()
        sessions.append(session)
        saveSessions(sessions)
    }

    static func loadTimerState() -> PomodoroTimerState {
        guard
            let data = AppGroup.defaults.data(forKey: AppGroup.Key.timerState),
            let state = try? decoder.decode(PomodoroTimerState.self, from: data)
        else {
            return PomodoroTimerState.makeReadyFocusState(using: loadSettings())
        }

        return state
    }

    static func saveTimerState(_ state: PomodoroTimerState) {
        guard let data = try? encoder.encode(state) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.timerState)
    }

    static func loadSyllabusStatuses() -> [String: SyllabusStatus] {
        guard
            let data = AppGroup.defaults.data(forKey: AppGroup.Key.syllabusStatuses),
            let statuses = try? decoder.decode([String: SyllabusStatus].self, from: data)
        else {
            return [:]
        }

        return statuses
    }

    static func saveSyllabusStatuses(_ statuses: [String: SyllabusStatus]) {
        guard let data = try? encoder.encode(statuses) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.Key.syllabusStatuses)
    }
}

import Foundation

enum AppGroup {
    static let defaults = UserDefaults.standard

    enum Key {
        static let settings = "barCommandCenter.settings"
        static let sessions = "barCommandCenter.sessions"
        static let timerState = "barCommandCenter.timerState"
        static let syllabusStatuses = "barCommandCenter.syllabusStatuses"
    }
}

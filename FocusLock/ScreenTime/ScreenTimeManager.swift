import Foundation

enum ScreenTimeManager {
    static func requestAuthorization() async throws {}

    static func authorizationLabel() -> String {
        "Mac dashboard mode"
    }

    static func scheduleDailyBoundaryMonitor() throws {}
}

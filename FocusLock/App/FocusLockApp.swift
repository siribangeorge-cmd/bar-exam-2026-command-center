import SwiftUI

@main
struct FocusLockApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onAppear {
                    model.bootstrap()
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        model.refreshOnForeground()
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}

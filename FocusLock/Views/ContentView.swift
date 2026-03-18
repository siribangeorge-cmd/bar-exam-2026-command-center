import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(model: model)
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                SyllabusView(model: model)
            }
            .tabItem {
                Label("Syllabus", systemImage: "text.badge.checkmark")
            }

            NavigationStack {
                HistoryView(model: model)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.xyaxis.line")
            }

            NavigationStack {
                SettingsView(model: model)
            }
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
        }
        .frame(minWidth: 1320, minHeight: 860)
        .preferredColorScheme(.dark)
        .alert("Something Needs Attention", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    model.dismissError()
                }
            }
        )) {
            Button("OK", role: .cancel) {
                model.dismissError()
            }
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }
}

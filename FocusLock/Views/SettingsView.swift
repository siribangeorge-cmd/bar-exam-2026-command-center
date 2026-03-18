import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Daily Goal") {
                HStack {
                    Text("Target hours")
                    Spacer()
                    Text(model.settings.dailyTargetHoursText)
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(model.settings.dailyTargetMinutes) / 60.0 },
                        set: { model.setDailyTargetHours($0) }
                    ),
                    in: 1...12,
                    step: 0.5
                )
            }

            Section("Pomodoro Rhythm") {
                Stepper(
                    "Focus block: \(model.settings.focusMinutes) min",
                    value: Binding(
                        get: { model.settings.focusMinutes },
                        set: { model.setFocusMinutes($0) }
                    ),
                    in: 15...90,
                    step: 5
                )

                Stepper(
                    "Short break: \(model.settings.shortBreakMinutes) min",
                    value: Binding(
                        get: { model.settings.shortBreakMinutes },
                        set: { model.setShortBreakMinutes($0) }
                    ),
                    in: 1...30,
                    step: 1
                )

                Stepper(
                    "Long break: \(model.settings.longBreakMinutes) min",
                    value: Binding(
                        get: { model.settings.longBreakMinutes },
                        set: { model.setLongBreakMinutes($0) }
                    ),
                    in: 5...60,
                    step: 5
                )

                Stepper(
                    "Long break after \(model.settings.sessionsBeforeLongBreak) focus blocks",
                    value: Binding(
                        get: { model.settings.sessionsBeforeLongBreak },
                        set: { model.setSessionsBeforeLongBreak($0) }
                    ),
                    in: 2...6
                )
            }

            Section("Syllabus Legend") {
                ForEach(SyllabusStatus.allCases) { status in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(status.tint)
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(status.shortTitle): \(status.title)")
                                .font(.body.weight(.semibold))
                            Text(status.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Data") {
                Button("Reset Syllabus Colors", role: .destructive) {
                    model.resetSyllabusStatuses()
                }

                Text("This clears only your section color tags. Your recorded study sessions stay intact.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}

import Foundation

struct WeekdayStudyAverage: Identifiable, Hashable {
    let weekday: Int
    let label: String
    let averageHours: Double

    var id: Int { weekday }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: StoredAppSettings
    @Published var snapshot: FocusProgressSnapshot
    @Published var timerState: PomodoroTimerState
    @Published var syllabusStatuses: [String: SyllabusStatus]
    @Published var selectedSubjectID: String
    @Published var searchText = ""
    @Published var currentDate: Date
    @Published var errorMessage: String?

    private let calendar: Calendar
    private var sessions: [FocusSession]

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.currentDate = .now

        let settings = SharedStore.loadSettings()
        let sessions = SharedStore.loadSessions()
        let analytics = FocusAnalytics(calendar: calendar)

        self.settings = settings
        self.sessions = sessions
        self.timerState = SharedStore.loadTimerState()
        self.syllabusStatuses = SharedStore.loadSyllabusStatuses()
        self.selectedSubjectID = SyllabusCatalog.subjects.first?.id ?? ""
        self.snapshot = analytics.progressSnapshot(
            sessions: sessions,
            for: .now,
            target: StudyTarget(dailyMinutes: settings.dailyTargetMinutes),
            recentHistoryDays: 30
        )

        reconcileTimerIfNeeded()
        refreshComputedState()
    }

    var subjects: [SyllabusSubject] {
        SyllabusCatalog.subjects
    }

    var selectedSubject: SyllabusSubject? {
        subjects.first(where: { $0.id == selectedSubjectID }) ?? subjects.first
    }

    var allTimeStudyHoursText: String {
        String(format: "%.1f hrs logged", Double(allTimeStudyMinutes) / 60.0)
    }

    var allTimeStudyMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var remainingTimeText: String {
        let remaining = timerState.remainingSeconds(now: currentDate, settings: settings)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var todayHoursText: String {
        String(format: "%.1f / %.1f hrs", snapshot.today.totalHours, Double(snapshot.today.targetMinutes) / 60.0)
    }

    var focusCompletionRatio: Double {
        guard snapshot.today.targetMinutes > 0 else { return 0 }
        return min(Double(snapshot.today.totalMinutes) / Double(snapshot.today.targetMinutes), 1)
    }

    var countdownDaysRemaining: Int {
        max(Int(ceil(examStartDate.timeIntervalSince(currentDate) / 86_400)), 0)
    }

    var countdownLabel: String {
        countdownDaysRemaining == 1 ? "1 day left" : "\(countdownDaysRemaining) days left"
    }

    var countdownDetail: String {
        examStartDate.formatted(
            .dateTime
                .month(.wide)
                .day()
                .year()
                .hour()
                .minute()
        ) + " • Manila time"
    }

    var syllabusCompletionRatio: Double {
        let sections = subjects.flatMap(\.sections)
        guard !sections.isEmpty else { return 0 }
        let total = sections.reduce(0.0) { partial, section in
            partial + status(for: section.id).progressScore
        }
        return total / Double(sections.count)
    }

    var examReadySectionsCount: Int {
        subjects
            .flatMap(\.sections)
            .filter { status(for: $0.id) == .examReady }
            .count
    }

    var goodStudyDaysCount: Int {
        snapshot.recentDailyHistory.filter { day in
            completionRatio(for: day) >= 0.8
        }.count
    }

    var badStudyDaysCount: Int {
        snapshot.recentDailyHistory.filter { day in
            completionRatio(for: day) > 0 && completionRatio(for: day) < 0.4
        }.count
    }

    var bestStudyDay: FocusDaySummary? {
        snapshot.recentDailyHistory.max(by: { $0.totalMinutes < $1.totalMinutes })
    }

    var bestWeekday: WeekdayStudyAverage? {
        weekdayAverages.max(by: { $0.averageHours < $1.averageHours })
    }

    var weakestWeekday: WeekdayStudyAverage? {
        weekdayAverages.min(by: { $0.averageHours < $1.averageHours })
    }

    var weekdayAverages: [WeekdayStudyAverage] {
        let grouped = Dictionary(grouping: snapshot.recentDailyHistory) { day in
            calendar.component(.weekday, from: day.dayStart)
        }

        return (1...7).compactMap { weekday in
            let days = grouped[weekday] ?? []
            guard !days.isEmpty else { return nil }
            let totalMinutes = days.reduce(0) { $0 + $1.totalMinutes }
            let label = calendar.weekdaySymbols[max(weekday - 1, 0)]
            return WeekdayStudyAverage(
                weekday: weekday,
                label: label,
                averageHours: Double(totalMinutes) / Double(days.count) / 60.0
            )
        }
    }

    var currentCycleText: String {
        timerState.completedFocusCycles == 1 ? "1 focus block done" : "\(timerState.completedFocusCycles) focus blocks done"
    }

    var examSchedule: [BarExamScheduleItem] {
        SyllabusCatalog.examSchedule
    }

    var bulletinURL: URL? {
        if let bundled = Bundle.main.url(forResource: "2026-Bar-Bulletin", withExtension: "pdf") {
            return bundled
        }

        let fallback = URL(fileURLWithPath: "/Users/georgesiriban/Documents/New project/FocusLock/Resources/2026-Bar-Bulletin.pdf")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }

    func bootstrap() {
        refreshComputedState()
    }

    func setSelectedSubject(_ subjectID: String) {
        selectedSubjectID = subjectID
    }

    func setSyllabusStatus(_ status: SyllabusStatus, for sectionID: String) {
        syllabusStatuses[sectionID] = status
        SharedStore.saveSyllabusStatuses(syllabusStatuses)
    }

    func resetSyllabusStatuses() {
        syllabusStatuses = [:]
        SharedStore.saveSyllabusStatuses(syllabusStatuses)
    }

    func status(for sectionID: String) -> SyllabusStatus {
        syllabusStatuses[sectionID] ?? .notStarted
    }

    func filteredSections(for subject: SyllabusSubject) -> [SyllabusSection] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return subject.sections
        }

        let query = searchText.lowercased()
        return subject.sections.filter { section in
            section.title.lowercased().contains(query)
        }
    }

    func progressRatio(for subject: SyllabusSubject) -> Double {
        guard !subject.sections.isEmpty else { return 0 }
        let total = subject.sections.reduce(0.0) { partial, section in
            partial + status(for: section.id).progressScore
        }
        return total / Double(subject.sections.count)
    }

    func readyCount(for subject: SyllabusSubject) -> Int {
        subject.sections.filter { status(for: $0.id) == .examReady }.count
    }

    func setDailyTargetHours(_ hours: Double) {
        settings.dailyTargetMinutes = max(Int(hours * 60), 30)
        persistSettings()
    }

    func setFocusMinutes(_ minutes: Int) {
        settings.focusMinutes = max(minutes, 5)
        persistSettings(resetTimerIfNeeded: !timerState.isRunning && timerState.phase == .focus)
    }

    func setShortBreakMinutes(_ minutes: Int) {
        settings.shortBreakMinutes = max(minutes, 1)
        persistSettings(resetTimerIfNeeded: !timerState.isRunning && timerState.phase == .shortBreak)
    }

    func setLongBreakMinutes(_ minutes: Int) {
        settings.longBreakMinutes = max(minutes, 5)
        persistSettings(resetTimerIfNeeded: !timerState.isRunning && timerState.phase == .longBreak)
    }

    func setSessionsBeforeLongBreak(_ count: Int) {
        settings.sessionsBeforeLongBreak = max(count, 2)
        persistSettings()
    }

    func toggleTimer() {
        if timerState.isRunning {
            timerState.pause(now: currentDate, settings: settings)
        } else {
            timerState.start(now: currentDate, settings: settings)
        }

        SharedStore.saveTimerState(timerState)
    }

    func skipCurrentPhase() {
        timerState.skip(using: settings)
        SharedStore.saveTimerState(timerState)
    }

    func handleTick() {
        currentDate = .now
        reconcileTimerIfNeeded()
    }

    func refreshOnForeground() {
        currentDate = .now
        refreshComputedState()
        reconcileTimerIfNeeded()
    }

    func dismissError() {
        errorMessage = nil
    }

    func completionRatio(for day: FocusDaySummary) -> Double {
        guard day.targetMinutes > 0 else { return 0 }
        return Double(day.totalMinutes) / Double(day.targetMinutes)
    }

    var bestStreak: Int {
        var longest = 0
        var running = 0

        for day in snapshot.recentDailyHistory {
            if completionRatio(for: day) >= 0.8 {
                running += 1
                longest = max(longest, running)
            } else {
                running = 0
            }
        }

        return longest
    }

    private func reconcileTimerIfNeeded() {
        if let completedSession = timerState.consumeElapsedTimer(now: currentDate, settings: settings) {
            SharedStore.appendSession(completedSession)
        }

        SharedStore.saveTimerState(timerState)
        refreshComputedState()
    }

    private func refreshComputedState() {
        let analytics = FocusAnalytics(calendar: calendar)
        sessions = SharedStore.loadSessions()
        snapshot = analytics.progressSnapshot(
            sessions: sessions,
            for: currentDate,
            target: StudyTarget(dailyMinutes: settings.dailyTargetMinutes),
            recentHistoryDays: 30
        )
    }

    private func persistSettings(resetTimerIfNeeded: Bool = false) {
        settings = settings.normalized()
        SharedStore.saveSettings(settings)

        if resetTimerIfNeeded {
            timerState = PomodoroTimerState.makeReadyFocusState(using: settings)
            SharedStore.saveTimerState(timerState)
        }

        refreshComputedState()
    }

    private var examStartDate: Date {
        Self.examStartDate
    }

    static let examStartDate: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Manila") ?? .current
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: 6, hour: 8, minute: 0)) ?? .now
    }()
}

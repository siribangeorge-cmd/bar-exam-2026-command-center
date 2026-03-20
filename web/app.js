import {
  DEFAULT_SETTINGS,
  EXAM_SCHEDULE,
  STATUS_META,
  SUBJECTS,
  TOTAL_SECTIONS,
} from "./data.js";

const STORAGE_KEYS = {
  settings: "bar2026.settings",
  sessions: "bar2026.sessions",
  syllabusStatuses: "bar2026.syllabusStatuses",
  timer: "bar2026.timer",
  activeView: "bar2026.activeView",
};

const EXAM_START = new Date("2026-09-06T08:00:00+08:00");
const PHASE_META = {
  focus: {
    title: "Focus",
    description: "Locked in. Build recall, finish a section, and leave proof on the board.",
  },
  shortBreak: {
    title: "Short Break",
    description: "Reset your eyes, breathe, and come back before the momentum drops.",
  },
  longBreak: {
    title: "Long Break",
    description: "A full reset after a strong block streak. Stretch, eat, and recover.",
  },
};
const NAV_ITEMS = [
  {
    id: "dashboard",
    label: "Dashboard",
    shortLabel: "Overview, countdown, and exam map",
  },
  {
    id: "pomodoro",
    label: "Pomodoro",
    shortLabel: "Focus timer and daily target",
  },
  {
    id: "syllabus",
    label: "Syllabus",
    shortLabel: "Track official coverage by subject",
  },
  {
    id: "insights",
    label: "Insights",
    shortLabel: "Study graphs and rhythm analysis",
  },
];

const statusMap = new Map(STATUS_META.map((status) => [status.id, status]));
const subjectMap = new Map(SUBJECTS.map((subject) => [subject.id, subject]));

const state = {
  settings: loadSettings(),
  sessions: loadSessions(),
  syllabusStatuses: loadSyllabusStatuses(),
  timer: null,
  selectedSubjectId: SUBJECTS[0]?.id ?? "",
  searchText: "",
  activeView: loadActiveView(),
};
const soundEngine = createSoundEngine();

state.timer = loadTimer(state.settings);
reconcileTimerState();
renderApp();
setInterval(handleTick, 1000);

document.querySelector("#app").addEventListener("click", handleClick);
document.querySelector("#app").addEventListener("input", handleInput);
document.querySelector("#app").addEventListener("change", handleChange);

function loadSettings() {
  try {
    const raw = JSON.parse(localStorage.getItem(STORAGE_KEYS.settings) ?? "null");
    return normalizeSettings(raw ?? DEFAULT_SETTINGS);
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

function saveSettings() {
  localStorage.setItem(STORAGE_KEYS.settings, JSON.stringify(state.settings));
}

function loadSessions() {
  try {
    const raw = JSON.parse(localStorage.getItem(STORAGE_KEYS.sessions) ?? "[]");
    return Array.isArray(raw)
      ? raw
          .filter((session) => session?.startAt && session?.endAt)
          .sort((left, right) => new Date(left.startAt) - new Date(right.startAt))
      : [];
  } catch {
    return [];
  }
}

function saveSessions() {
  localStorage.setItem(STORAGE_KEYS.sessions, JSON.stringify(state.sessions));
}

function loadSyllabusStatuses() {
  try {
    const raw = JSON.parse(localStorage.getItem(STORAGE_KEYS.syllabusStatuses) ?? "{}");
    return raw && typeof raw === "object" ? raw : {};
  } catch {
    return {};
  }
}

function saveSyllabusStatuses() {
  localStorage.setItem(STORAGE_KEYS.syllabusStatuses, JSON.stringify(state.syllabusStatuses));
}

function loadTimer(settings) {
  try {
    const raw = JSON.parse(localStorage.getItem(STORAGE_KEYS.timer) ?? "null");
    return normalizeTimer(raw, settings);
  } catch {
    return makeDefaultTimer(settings);
  }
}

function saveTimer() {
  localStorage.setItem(STORAGE_KEYS.timer, JSON.stringify(state.timer));
}

function loadActiveView() {
  const raw = localStorage.getItem(STORAGE_KEYS.activeView);
  if (raw === "settings") {
    return "pomodoro";
  }
  return NAV_ITEMS.some((item) => item.id === raw) ? raw : "dashboard";
}

function saveActiveView() {
  localStorage.setItem(STORAGE_KEYS.activeView, state.activeView);
}

function normalizeSettings(raw) {
  return {
    dailyTargetMinutes: Math.max(Number(raw?.dailyTargetMinutes) || DEFAULT_SETTINGS.dailyTargetMinutes, 30),
    focusMinutes: Math.max(Number(raw?.focusMinutes) || DEFAULT_SETTINGS.focusMinutes, 5),
    shortBreakMinutes: Math.max(Number(raw?.shortBreakMinutes) || DEFAULT_SETTINGS.shortBreakMinutes, 1),
    longBreakMinutes: Math.max(Number(raw?.longBreakMinutes) || DEFAULT_SETTINGS.longBreakMinutes, 5),
    sessionsBeforeLongBreak: Math.max(Number(raw?.sessionsBeforeLongBreak) || DEFAULT_SETTINGS.sessionsBeforeLongBreak, 2),
    soundEnabled: raw?.soundEnabled ?? DEFAULT_SETTINGS.soundEnabled,
  };
}

function makeDefaultTimer(settings) {
  return {
    phase: "focus",
    isRunning: false,
    remainingSeconds: settings.focusMinutes * 60,
    endsAt: null,
    completedFocusCycles: 0,
  };
}

function normalizeTimer(raw, settings) {
  if (!raw || typeof raw !== "object") {
    return makeDefaultTimer(settings);
  }

  const phase = Object.prototype.hasOwnProperty.call(PHASE_META, raw.phase) ? raw.phase : "focus";
  const duration = phaseDurationSeconds(phase);
  const remainingSeconds = Math.max(1, Number(raw.remainingSeconds) || duration);

  return {
    phase,
    isRunning: Boolean(raw.isRunning),
    remainingSeconds: remainingSeconds,
    endsAt: raw.endsAt ?? null,
    completedFocusCycles: Math.max(0, Number(raw.completedFocusCycles) || 0),
  };
}

function phaseDurationSeconds(phase) {
  if (phase === "shortBreak") {
    return state.settings.shortBreakMinutes * 60;
  }
  if (phase === "longBreak") {
    return state.settings.longBreakMinutes * 60;
  }
  return state.settings.focusMinutes * 60;
}

function selectedSubject() {
  return subjectMap.get(state.selectedSubjectId) ?? SUBJECTS[0];
}

function statusFor(sectionId) {
  return statusMap.get(state.syllabusStatuses[sectionId] ?? "notStarted") ?? STATUS_META[0];
}

function completionRatio(daySummary) {
  if (!daySummary.targetMinutes) {
    return 0;
  }
  return daySummary.totalMinutes / daySummary.targetMinutes;
}

function getRecentDailyHistory(days = 30) {
  const end = startOfDay(new Date());
  const history = [];

  for (let index = days - 1; index >= 0; index -= 1) {
    const dayStart = new Date(end);
    dayStart.setDate(end.getDate() - index);
    const dayEnd = new Date(dayStart);
    dayEnd.setDate(dayStart.getDate() + 1);

    const totalMinutes = state.sessions.reduce((sum, session) => {
      return sum + overlappingMinutes(session, dayStart, dayEnd);
    }, 0);

    history.push({
      dayStart,
      totalMinutes,
      targetMinutes: state.settings.dailyTargetMinutes,
      totalHours: totalMinutes / 60,
    });
  }

  return history;
}

function totalMinutesForDate(date) {
  const dayStart = startOfDay(date);
  const dayEnd = new Date(dayStart);
  dayEnd.setDate(dayStart.getDate() + 1);

  return state.sessions.reduce((sum, session) => {
    return sum + overlappingMinutes(session, dayStart, dayEnd);
  }, 0);
}

function overlappingMinutes(session, intervalStart, intervalEnd) {
  const start = Math.max(new Date(session.startAt).getTime(), intervalStart.getTime());
  const end = Math.min(new Date(session.endAt).getTime(), intervalEnd.getTime());
  if (end <= start) {
    return 0;
  }
  return Math.floor((end - start) / 60000);
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function analytics() {
  const recent30 = getRecentDailyHistory(30);
  const today = recent30[recent30.length - 1];
  const recent14 = recent30.slice(-14);
  const allTimeMinutes = state.sessions.reduce((sum, session) => {
    return sum + Math.max(0, Math.floor((new Date(session.endAt) - new Date(session.startAt)) / 60000));
  }, 0);
  const syllabusRatio = SUBJECTS.flatMap((subject) => subject.sections).reduce((sum, section) => {
    return sum + statusFor(section.id).progressScore;
  }, 0) / TOTAL_SECTIONS;
  const examReadySections = SUBJECTS.flatMap((subject) => subject.sections).filter((section) => statusFor(section.id).id === "examReady").length;
  const goodDays = recent30.filter((day) => completionRatio(day) >= 0.8).length;
  const weakerDays = recent30.filter((day) => completionRatio(day) > 0 && completionRatio(day) < 0.4).length;
  const bestDay = [...recent30].sort((left, right) => right.totalMinutes - left.totalMinutes)[0];
  const weekdayMap = new Map();

  recent30.forEach((day) => {
    const weekday = day.dayStart.getDay();
    const entry = weekdayMap.get(weekday) ?? { totalMinutes: 0, count: 0 };
    entry.totalMinutes += day.totalMinutes;
    entry.count += 1;
    weekdayMap.set(weekday, entry);
  });

  const weekdayAverages = [0, 1, 2, 3, 4, 5, 6].map((weekday) => {
    const entry = weekdayMap.get(weekday);
    const label = new Intl.DateTimeFormat("en-US", { weekday: "short" }).format(
      new Date(2026, 2, 15 + weekday),
    );
    return {
      weekday,
      label,
      averageHours: entry ? entry.totalMinutes / entry.count / 60 : 0,
    };
  });

  const bestWeekday = [...weekdayAverages].sort((left, right) => right.averageHours - left.averageHours)[0];
  const bestStreak = longestStreak(recent30);

  return {
    today,
    recent14,
    recent30,
    allTimeMinutes,
    syllabusRatio,
    examReadySections,
    goodDays,
    weakerDays,
    bestDay,
    bestWeekday,
    bestStreak,
    weekdayAverages,
  };
}

function longestStreak(days) {
  let longest = 0;
  let running = 0;

  days.forEach((day) => {
    if (completionRatio(day) >= 0.8) {
      running += 1;
      longest = Math.max(longest, running);
    } else {
      running = 0;
    }
  });

  return longest;
}

function reconcileTimerState() {
  if (!state.timer.isRunning || !state.timer.endsAt) {
    return false;
  }

  const now = Date.now();
  const end = new Date(state.timer.endsAt).getTime();

  if (now < end) {
    state.timer.remainingSeconds = Math.max(1, Math.ceil((end - now) / 1000));
    return false;
  }

  transitionAfterCurrentPhase(end, true);
  return true;
}

function transitionAfterCurrentPhase(referenceTime, shouldRecordFocus) {
  const currentPhase = state.timer.phase;
  const referenceDate = new Date(referenceTime);
  let targetJustHit = false;

  if (currentPhase === "focus" && shouldRecordFocus) {
    const durationMs = state.settings.focusMinutes * 60 * 1000;
    const previousTodayMinutes = totalMinutesForDate(referenceDate);
    const session = {
      id: crypto.randomUUID(),
      startAt: new Date(referenceTime - durationMs).toISOString(),
      endAt: new Date(referenceTime).toISOString(),
    };
    state.sessions.push(session);
    state.sessions.sort((left, right) => new Date(left.startAt) - new Date(right.startAt));
    saveSessions();
    state.timer.completedFocusCycles += 1;
    targetJustHit = previousTodayMinutes < state.settings.dailyTargetMinutes
      && previousTodayMinutes + state.settings.focusMinutes >= state.settings.dailyTargetMinutes;
  }

  const nextPhase = currentPhase === "focus"
    ? (state.timer.completedFocusCycles % state.settings.sessionsBeforeLongBreak === 0 ? "longBreak" : "shortBreak")
    : "focus";

  const nextDuration = phaseDurationSeconds(nextPhase);
  state.timer.phase = nextPhase;
  state.timer.isRunning = true;
  state.timer.remainingSeconds = nextDuration;
  state.timer.endsAt = new Date(Date.now() + nextDuration * 1000).toISOString();
  saveTimer();

  if (state.settings.soundEnabled) {
    if (currentPhase === "focus") {
      if (targetJustHit) {
        soundEngine.playTargetHit();
      } else {
        soundEngine.playFocusComplete(nextPhase === "longBreak");
      }
    } else {
      soundEngine.playBreakComplete(currentPhase === "longBreak");
      soundEngine.playFocusStart(320);
    }
  }
}

function handleTick() {
  if (state.timer.isRunning && reconcileTimerState()) {
    renderApp();
    return;
  }

  updateCountdownUI();
  updateTimerUI();
}

function handleClick(event) {
  const button = event.target.closest("[data-action], [data-subject-id], [data-open-pdf], [data-view]");
  if (!button) {
    return;
  }

  soundEngine.arm();

  const nextView = button.getAttribute("data-view");
  if (nextView) {
    state.activeView = nextView;
    saveActiveView();
    renderApp();
    return;
  }

  const subjectId = button.getAttribute("data-subject-id");
  if (subjectId) {
    state.selectedSubjectId = subjectId;
    renderApp();
    return;
  }

  if (button.hasAttribute("data-open-pdf")) {
    window.open(pdfURLForSubject(selectedSubject()), "_blank", "noopener");
    return;
  }

  const action = button.getAttribute("data-action");

  if (action === "toggle-timer") {
    toggleTimer();
  } else if (action === "skip-phase") {
    skipPhase();
  } else if (action === "reset-timer") {
    state.timer = makeDefaultTimer(state.settings);
    saveTimer();
  } else if (action === "reset-syllabus") {
    state.syllabusStatuses = {};
    saveSyllabusStatuses();
  } else if (action === "preview-sound") {
    soundEngine.preview();
  } else if (action === "preview-focus-start") {
    soundEngine.playFocusStart();
  } else if (action === "preview-break-start") {
    soundEngine.playBreakStart();
  } else if (action === "preview-focus-complete") {
    soundEngine.playFocusComplete(false);
  } else if (action === "preview-target-hit") {
    soundEngine.playTargetHit();
  }

  renderApp();
}

function handleInput(event) {
  const target = event.target;

  if (target.matches("[data-search]")) {
    state.searchText = target.value;
    renderApp();
  }
}

function handleChange(event) {
  const target = event.target;

  if (target.matches("[data-section-status]")) {
    const sectionId = target.getAttribute("data-section-status");
    state.syllabusStatuses[sectionId] = target.value;
    saveSyllabusStatuses();
    renderApp();
    return;
  }

  if (target.matches("[data-setting]")) {
    const key = target.getAttribute("data-setting");
    const value = Number(target.value);
    state.settings[key] = value;
    state.settings = normalizeSettings(state.settings);

    if (!state.timer.isRunning) {
      state.timer.remainingSeconds = phaseDurationSeconds(state.timer.phase);
    }

    saveSettings();
    saveTimer();
    renderApp();
    return;
  }

  if (target.matches("[data-setting-boolean]")) {
    const key = target.getAttribute("data-setting-boolean");
    state.settings[key] = target.checked;
    state.settings = normalizeSettings(state.settings);
    saveSettings();
    renderApp();
  }
}

function toggleTimer() {
  if (state.timer.isRunning) {
    const remaining = Math.max(1, Math.ceil((new Date(state.timer.endsAt).getTime() - Date.now()) / 1000));
    state.timer.isRunning = false;
    state.timer.remainingSeconds = remaining;
    state.timer.endsAt = null;
  } else {
    state.timer.isRunning = true;
    state.timer.endsAt = new Date(Date.now() + state.timer.remainingSeconds * 1000).toISOString();

    if (state.settings.soundEnabled) {
      if (state.timer.phase === "focus") {
        soundEngine.playFocusStart();
      } else {
        soundEngine.playBreakStart();
      }
    }
  }
  saveTimer();
}

function skipPhase() {
  const shouldRecordFocus = false;
  state.timer.isRunning = false;
  state.timer.endsAt = null;

  if (state.timer.phase === "focus") {
    state.timer.phase = "shortBreak";
    state.timer.remainingSeconds = state.settings.shortBreakMinutes * 60;
  } else {
    state.timer.phase = "focus";
    state.timer.remainingSeconds = state.settings.focusMinutes * 60;
  }

  if (shouldRecordFocus) {
    saveSessions();
  }

  saveTimer();
}

function renderApp() {
  const data = analytics();
  const currentSubject = selectedSubject();
  const filteredSections = currentSubject.sections.filter((section) => {
    const query = state.searchText.trim().toLowerCase();
    if (!query) {
      return true;
    }
    return section.title.toLowerCase().includes(query);
  });
  const countdown = countdownText();
  const meta = viewMeta();

  document.querySelector("#app").innerHTML = `
    <div class="app-shell">
      <aside class="card nav-shell">
        <div class="nav-aura"></div>
        <div class="nav-head">
          <img class="brand-mark" src="./assets/app-icon-192.png" alt="Bar Exam 2026 logo">
          <div class="brand-copy">
            <p class="brand-overline">Made by siribangeorge</p>
            <h1>Bar Exam 2026</h1>
            <p>Command Center</p>
          </div>
        </div>
        <nav class="nav-menu">
          ${NAV_ITEMS.map((item) => renderNavButton(item, data)).join("")}
        </nav>
        <div class="nav-footer-stack">
          <article class="nav-summary">
            <span class="metric-label">Until first exam</span>
            <strong class="nav-summary-value" id="countdown-days-side">${countdown.daysLabel}</strong>
            <p class="nav-summary-copy" id="countdown-detail-side">${countdown.sideLabel}</p>
            <div class="nav-summary-grid">
              <div class="nav-summary-tile">
                <span class="subdued">Today</span>
                <strong>${formatHours(data.today.totalHours)}</strong>
              </div>
              <div class="nav-summary-tile">
                <span class="subdued">Coverage</span>
                <strong>${Math.round(data.syllabusRatio * 100)}%</strong>
              </div>
            </div>
          </article>
        </div>
      </aside>

      <section class="workspace-shell">
        ${renderWorkspaceHeader(data, countdown, meta)}

        <main class="page-shell">
          ${renderActiveView(data, currentSubject, filteredSections)}
        </main>
      </section>
    </div>
  `;

  updateCountdownUI();
  updateTimerUI();
}

function viewMeta() {
  if (state.activeView === "pomodoro") {
    return {
      kicker: "Focus Studio",
      title: "Pomodoro Sessions",
      description: "Run clean study blocks, keep the timer front and center, and see exactly how today is stacking up against your target.",
    };
  }

  if (state.activeView === "syllabus") {
    return {
      kicker: "Syllabus Atlas",
      title: "Official Coverage Tracker",
      description: "Navigate the main Roman numeral topics subject by subject, color-code your mastery, and keep the bulletin PDF beside you.",
    };
  }

  if (state.activeView === "insights") {
    return {
      kicker: "Performance Room",
      title: "Study Insights",
      description: "Review your recent output, identify your strongest rhythm, and separate strong study days from the ones that need recovery.",
    };
  }

  return {
    kicker: "Dashboard",
    title: "Bar Exam 2026",
    description: "Countdown, progress, and exam-day readiness in one place.",
  };
}

function renderWorkspaceHeader(data, countdown, meta) {
  if (state.activeView === "dashboard") {
    return `
      <header class="card workspace-topbar dashboard-topbar">
        <div class="dashboard-topbar-main">
          <p class="workspace-kicker">Countdown</p>
          <h2 class="dashboard-countdown" id="countdown-days-top">${countdown.daysLabel}</h2>
          <p class="workspace-copy dashboard-countdown-copy" id="countdown-detail-top">${countdown.detailLabel}</p>
        </div>
        <div class="workspace-pulse">
          <div class="pulse-pill">
            <span class="subdued">Target</span>
            <strong>${formatHours(state.settings.dailyTargetMinutes / 60)}</strong>
          </div>
          <div class="pulse-pill">
            <span class="subdued">Focus</span>
            <strong>${state.settings.focusMinutes} min</strong>
          </div>
          <div class="pulse-pill">
            <span class="subdued">Ready</span>
            <strong>${data.examReadySections}/${TOTAL_SECTIONS}</strong>
          </div>
        </div>
      </header>
    `;
  }

  return `
    <header class="card workspace-topbar">
      <div class="workspace-title-block">
        <p class="workspace-kicker">${meta.kicker}</p>
        <h2>${meta.title}</h2>
        <p class="workspace-copy">${meta.description}</p>
      </div>
      <div class="workspace-pulse">
        <div class="pulse-pill">
          <span class="subdued">Target</span>
          <strong>${formatHours(state.settings.dailyTargetMinutes / 60)}</strong>
        </div>
        <div class="pulse-pill">
          <span class="subdued">Focus</span>
          <strong>${state.settings.focusMinutes} min</strong>
        </div>
        <div class="pulse-pill">
          <span class="subdued">Ready</span>
          <strong>${data.examReadySections}/${TOTAL_SECTIONS}</strong>
        </div>
      </div>
    </header>
  `;
}

function renderNavButton(item, data) {
  const activeClass = item.id === state.activeView ? "is-active" : "";
  let meta = item.shortLabel;

  if (item.id === "dashboard") {
    meta = countdownText().daysLabel;
  } else if (item.id === "pomodoro") {
    meta = `${state.timer.completedFocusCycles} blocks done`;
  } else if (item.id === "syllabus") {
    meta = `${data.examReadySections}/${TOTAL_SECTIONS} exam-ready`;
  } else if (item.id === "insights") {
    meta = `${data.goodDays} strong days`;
  }

  return `
    <button class="nav-button ${activeClass}" data-view="${item.id}">
      <span class="nav-button-line"></span>
      <span class="nav-button-body">
        <strong>${item.label}</strong>
        <small>${item.shortLabel}</small>
      </span>
      <span class="nav-button-meta">${meta}</span>
    </button>
  `;
}

function renderActiveView(data, currentSubject, filteredSections) {
  if (state.activeView === "pomodoro") {
    return renderPomodoroView(data);
  }

  if (state.activeView === "syllabus") {
    return renderSyllabusView(currentSubject, filteredSections);
  }

  if (state.activeView === "insights") {
    return renderInsightsView(data);
  }

  return renderDashboardView(data);
}

function renderDashboardView(data) {
  return `
    <section class="content-grid cols-2 dashboard-stats-grid">
      ${renderTargetCard(data)}
      ${renderSyllabusCoverageCard(data)}
    </section>

    <section class="content-grid cols-2">
      <article class="card panel">
        <h3>Exam Week Map</h3>
        <div class="schedule-list">
          ${EXAM_SCHEDULE.map(renderScheduleItem).join("")}
        </div>
      </article>
      <article class="card chart-card">
        <h3>Study Pulse</h3>
        <div class="chart-shell">${renderDailyChart(data.recent14, state.settings.dailyTargetMinutes / 60)}</div>
        <div class="chart-caption">Last 14 days. Green means target met, amber means close, red means a weak day, and dim bars mean no recorded study.</div>
      </article>
      <article class="card chart-card">
        <h3>Quick Insight Snapshot</h3>
        <div class="summary-grid summary-grid-2">
          <div class="summary-card">
            <span class="subdued">All-time logged</span>
            <strong>${formatHours(data.allTimeMinutes / 60)}</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Good days</span>
            <strong>${data.goodDays}</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Needs rescue</span>
            <strong>${data.weakerDays}</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Best weekday</span>
            <strong>${data.bestWeekday?.label ?? "N/A"}</strong>
          </div>
        </div>
        <div class="chart-shell chart-shell-tight">${renderWeekdayChart(data.weekdayAverages)}</div>
      </article>
    </section>
  `;
}

function renderPomodoroView(data) {
  const ratio = Math.min(completionRatio(data.today), 1);

  return `
    <section class="page-section focus-hero-grid">
      <article class="card timer-showcase">
        <div class="timer-headline-row">
          <div class="phase-chip" id="timer-phase">${PHASE_META[state.timer.phase].title}</div>
          <span class="session-state">${state.timer.isRunning ? "Session live" : "Ready to begin"}</span>
        </div>
        <div class="timer-clock timer-clock-large" id="timer-clock">${formatClock(state.timer.remainingSeconds)}</div>
        <p class="subdued timer-voice" id="timer-note">${PHASE_META[state.timer.phase].description}</p>
        <div class="timer-chip-row">
          <span class="pill">${state.timer.completedFocusCycles} focus blocks done</span>
          <span class="pill">${state.timer.isRunning ? "Running now" : "Paused"}</span>
          <span class="pill">${formatHours(data.today.totalHours)} logged today</span>
        </div>
        <div class="button-row">
          <button class="button button-primary" data-action="toggle-timer">${state.timer.isRunning ? "Pause" : "Start Focus"}</button>
          <button class="button button-secondary" data-action="skip-phase">Skip Phase</button>
          <button class="button button-danger" data-action="reset-timer">Reset Timer</button>
        </div>
      </article>

      <article class="card panel cadence-card">
        <h3>Focus Cadence</h3>
        <div class="summary-grid summary-grid-2">
          <div class="summary-card">
            <span class="subdued">Daily target</span>
            <strong>${formatHours(state.settings.dailyTargetMinutes / 60)}</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Focus block</span>
            <strong>${state.settings.focusMinutes} min</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Short break</span>
            <strong>${state.settings.shortBreakMinutes} min</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Long break</span>
            <strong>${state.settings.longBreakMinutes} min</strong>
          </div>
        </div>
        <div class="focus-progress-wrap">
          <div class="focus-progress-label">
            <span class="subdued">Today’s target progress</span>
            <strong>${Math.round(ratio * 100)}%</strong>
          </div>
          <div class="progress-track"><div class="progress-fill" style="width:${Math.round(ratio * 100)}%;"></div></div>
        </div>
        <p class="chart-caption">Your timer is separated here so you can stay locked in without the rest of the dashboard competing for attention.</p>
      </article>
    </section>

    <section class="content-grid">
      <article class="card chart-card">
        <h3>Recent Focus Rhythm</h3>
        <div class="chart-shell">${renderDailyChart(data.recent14, state.settings.dailyTargetMinutes / 60)}</div>
        <div class="chart-caption">A quick read on whether your last two weeks are compounding or slipping.</div>
      </article>
    </section>

    <section class="content-grid cols-2">
      <article class="card settings-card">
        <h3>Adjust Pomodoro</h3>
        <p class="setting-help">Tune the timer here without leaving the Pomodoro page.</p>
        <div class="settings-grid settings-grid-wide">
          <div class="setting-group">
            <label for="pomodoroDailyTargetMinutes">Daily target minutes</label>
            <input class="input" id="pomodoroDailyTargetMinutes" type="number" min="30" step="30" data-setting="dailyTargetMinutes" value="${state.settings.dailyTargetMinutes}">
          </div>
          <div class="setting-group">
            <label for="pomodoroFocusMinutes">Focus minutes</label>
            <input class="input" id="pomodoroFocusMinutes" type="number" min="5" step="5" data-setting="focusMinutes" value="${state.settings.focusMinutes}">
          </div>
          <div class="setting-group">
            <label for="pomodoroShortBreakMinutes">Short break minutes</label>
            <input class="input" id="pomodoroShortBreakMinutes" type="number" min="1" step="1" data-setting="shortBreakMinutes" value="${state.settings.shortBreakMinutes}">
          </div>
          <div class="setting-group">
            <label for="pomodoroLongBreakMinutes">Long break minutes</label>
            <input class="input" id="pomodoroLongBreakMinutes" type="number" min="5" step="5" data-setting="longBreakMinutes" value="${state.settings.longBreakMinutes}">
          </div>
          <div class="setting-group">
            <label for="pomodoroSessionsBeforeLongBreak">Focus sessions before long break</label>
            <input class="input" id="pomodoroSessionsBeforeLongBreak" type="number" min="2" step="1" data-setting="sessionsBeforeLongBreak" value="${state.settings.sessionsBeforeLongBreak}">
          </div>
        </div>
      </article>

      <article class="card settings-card">
        <h3>Sound Cues</h3>
        <div class="setting-group">
          <label class="toggle-row" for="pomodoroSoundEnabled">
            <span>Play Pomodoro milestone sounds</span>
            <input id="pomodoroSoundEnabled" type="checkbox" data-setting-boolean="soundEnabled" ${state.settings.soundEnabled ? "checked" : ""}>
          </label>
        </div>
        <div class="sound-preview-list">
          <div class="sound-preview-row">
            <div>
              <strong>Focus start</strong>
              <p class="setting-help">Plays when a focus block begins.</p>
            </div>
            <button class="button button-secondary" data-action="preview-focus-start">Preview</button>
          </div>
          <div class="sound-preview-row">
            <div>
              <strong>Break start</strong>
              <p class="setting-help">Plays when a break begins.</p>
            </div>
            <button class="button button-secondary" data-action="preview-break-start">Preview</button>
          </div>
          <div class="sound-preview-row">
            <div>
              <strong>Focus complete</strong>
              <p class="setting-help">Warm chime when a focus block ends.</p>
            </div>
            <button class="button button-secondary" data-action="preview-focus-complete">Preview</button>
          </div>
          <div class="sound-preview-row">
            <div>
              <strong>Daily target hit</strong>
              <p class="setting-help">Success cue when you hit your target.</p>
            </div>
            <button class="button button-secondary" data-action="preview-target-hit">Preview</button>
          </div>
        </div>
      </article>
    </section>
  `;
}

function renderSyllabusView(currentSubject, filteredSections) {
  const subjectRatio = Math.round(subjectProgress(currentSubject) * 100);
  const readyCount = currentSubject.sections.filter((section) => statusFor(section.id).id === "examReady").length;

  return `
    <section class="page-section">
      <div class="content-grid cols-2">
        <article class="card subject-hero-card">
          <p class="eyebrow">Current subject</p>
          <h3>${currentSubject.title}</h3>
          <p class="subject-meta">${currentSubject.examWindow} • ${currentSubject.examDay} • ${currentSubject.weight}</p>
          <p>${currentSubject.summary}</p>
          <div class="subject-hero-stats">
            <div class="summary-card">
              <span class="subdued">Coverage</span>
              <strong>${subjectRatio}%</strong>
            </div>
            <div class="summary-card">
              <span class="subdued">Exam-ready</span>
              <strong>${readyCount}/${currentSubject.sections.length}</strong>
            </div>
          </div>
          <div class="button-row">
            <button class="button button-secondary" data-open-pdf="true">Open PDF in New Tab</button>
            <button class="button button-secondary" data-action="reset-syllabus">Reset All Statuses</button>
          </div>
        </article>

        <article class="card panel">
          <h3>Exam Week Map</h3>
          <div class="schedule-list">
            ${EXAM_SCHEDULE.map(renderScheduleItem).join("")}
          </div>
        </article>
      </div>
    </section>

    <section class="syllabus-layout">
      <aside class="card subject-list">
        <h3>Subjects</h3>
        <p>Select a subject to inspect only its official main topics and progress.</p>
        <div class="subject-buttons">
          ${SUBJECTS.map((subject) => renderSubjectButton(subject)).join("")}
        </div>
      </aside>

      <article class="card subject-pane">
        <h2>${currentSubject.title}</h2>
        <p class="subject-meta">${currentSubject.examWindow} • Bulletin pages ${currentSubject.bulletinPageRange[0]}-${currentSubject.bulletinPageRange[1]}</p>
        <div class="legend-grid subject-legend-grid">
          ${STATUS_META.map((status) => `
            <div class="legend-item" style="background:${status.soft};">
              <strong><span class="color-dot" style="background:${status.color};"></span>${status.shortTitle}</strong>
              <span class="subdued">${status.title}</span>
            </div>
          `).join("")}
        </div>
        <div class="field-row">
          <input class="input" type="search" data-search placeholder="Filter main topics" value="${escapeAttribute(state.searchText)}">
          <span class="pill">${filteredSections.length} visible topics</span>
        </div>
        <div class="section-list">
          ${filteredSections.map((section) => renderSectionRow(section)).join("")}
        </div>
      </article>

      <article class="card pdf-pane">
        <h3>Bulletin PDF</h3>
        <p>The embedded viewer opens directly to this subject’s page range. If the preview is blank, open it in a new tab.</p>
        <iframe
          class="pdf-frame"
          title="2026 Bar Bulletin"
          src="${pdfURLForSubject(currentSubject)}"
        ></iframe>
      </article>
    </section>
  `;
}

function renderInsightsView(data) {
  return `
    <section class="page-section insights-strip">
      <article class="card summary-card spotlight-card">
        <span class="subdued">All-time logged</span>
        <strong>${formatHours(data.allTimeMinutes / 60)}</strong>
        <p class="chart-caption">Every finished focus block contributes here.</p>
      </article>
      <article class="card summary-card spotlight-card">
        <span class="subdued">Good days</span>
        <strong>${data.goodDays}</strong>
        <p class="chart-caption">Days where you reached at least 80% of target.</p>
      </article>
      <article class="card summary-card spotlight-card">
        <span class="subdued">Needs rescue</span>
        <strong>${data.weakerDays}</strong>
        <p class="chart-caption">Days with some study, but not enough momentum.</p>
      </article>
      <article class="card summary-card spotlight-card">
        <span class="subdued">Best streak</span>
        <strong>${data.bestStreak} ${data.bestStreak === 1 ? "day" : "days"}</strong>
        <p class="chart-caption">Your longest run of strong study days.</p>
      </article>
    </section>

    <section class="content-grid cols-2">
      <article class="card chart-card">
        <h3>Last 30 Days</h3>
        <div class="chart-shell">${renderDailyChart(data.recent30, state.settings.dailyTargetMinutes / 60)}</div>
        <div class="chart-caption">Each bar is one day of recorded study from your Pomodoro sessions.</div>
      </article>
      <article class="card chart-card">
        <h3>Weekday Rhythm</h3>
        <div class="chart-shell">${renderWeekdayChart(data.weekdayAverages)}</div>
        <div class="chart-caption">Strongest weekday: ${data.bestWeekday?.label ?? "N/A"}.</div>
      </article>
    </section>

    <section class="content-grid cols-2">
      <article class="card chart-card">
        <h3>What the Graph Says</h3>
        <div class="summary-grid summary-grid-2">
          <div class="summary-card">
            <span class="subdued">Today</span>
            <strong>${formatHours(data.today.totalHours)}</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Target completion</span>
            <strong>${Math.round(Math.min(completionRatio(data.today), 1) * 100)}%</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Exam-ready sections</span>
            <strong>${data.examReadySections}/${TOTAL_SECTIONS}</strong>
          </div>
          <div class="summary-card">
            <span class="subdued">Coverage score</span>
            <strong>${Math.round(data.syllabusRatio * 100)}%</strong>
          </div>
        </div>
        <p class="chart-caption">
          Best day: ${data.bestDay ? `${formatShortDate(data.bestDay.dayStart)} at ${formatHours(data.bestDay.totalHours)}` : "No sessions yet"}.
        </p>
      </article>
      <article class="card panel">
        <h3>Reading the Pattern</h3>
        <div class="insight-list">
          <div class="insight-row">
            <span class="subdued">Best weekday</span>
            <strong>${data.bestWeekday?.label ?? "N/A"}</strong>
          </div>
          <div class="insight-row">
            <span class="subdued">Good days</span>
            <strong>${data.goodDays}</strong>
          </div>
          <div class="insight-row">
            <span class="subdued">Weaker days</span>
            <strong>${data.weakerDays}</strong>
          </div>
          <div class="insight-row">
            <span class="subdued">Current target</span>
            <strong>${formatHours(state.settings.dailyTargetMinutes / 60)}</strong>
          </div>
        </div>
      </article>
    </section>
  `;
}

function renderSettingsView() {
  return `
    <section class="page-section">
      <div class="content-grid cols-2">
        <article class="card settings-card">
          <h3>Pomodoro Setup</h3>
          <p class="setting-help">Adjust your study target and timer lengths here. Changes save instantly in this browser.</p>
          <div class="settings-grid settings-grid-wide">
            <div class="setting-group">
              <label for="dailyTargetMinutes">Daily target minutes</label>
              <input class="input" id="dailyTargetMinutes" type="number" min="30" step="30" data-setting="dailyTargetMinutes" value="${state.settings.dailyTargetMinutes}">
            </div>
            <div class="setting-group">
              <label for="focusMinutes">Focus minutes</label>
              <input class="input" id="focusMinutes" type="number" min="5" step="5" data-setting="focusMinutes" value="${state.settings.focusMinutes}">
            </div>
            <div class="setting-group">
              <label for="shortBreakMinutes">Short break minutes</label>
              <input class="input" id="shortBreakMinutes" type="number" min="1" step="1" data-setting="shortBreakMinutes" value="${state.settings.shortBreakMinutes}">
            </div>
            <div class="setting-group">
              <label for="longBreakMinutes">Long break minutes</label>
              <input class="input" id="longBreakMinutes" type="number" min="5" step="5" data-setting="longBreakMinutes" value="${state.settings.longBreakMinutes}">
            </div>
            <div class="setting-group">
              <label for="sessionsBeforeLongBreak">Focus sessions before long break</label>
              <input class="input" id="sessionsBeforeLongBreak" type="number" min="2" step="1" data-setting="sessionsBeforeLongBreak" value="${state.settings.sessionsBeforeLongBreak}">
            </div>
          </div>
        </article>
        <article class="card settings-card">
          <h3>Current Setup</h3>
          <p class="setting-help">If a timer is already running, your new durations will fully apply on the next fresh phase.</p>
          <div class="summary-grid summary-grid-2">
            <div class="summary-card">
              <span class="subdued">Focus</span>
              <strong>${state.settings.focusMinutes} min</strong>
            </div>
            <div class="summary-card">
              <span class="subdued">Target</span>
              <strong>${formatHours(state.settings.dailyTargetMinutes / 60)}</strong>
            </div>
            <div class="summary-card">
              <span class="subdued">Short break</span>
              <strong>${state.settings.shortBreakMinutes} min</strong>
            </div>
            <div class="summary-card">
              <span class="subdued">Long break</span>
              <strong>${state.settings.longBreakMinutes} min</strong>
            </div>
          </div>
          <p class="setting-help">Your timer, syllabus statuses, and study history stay saved locally on the device and browser you are using.</p>
        </article>
      </div>
    </section>

    <section class="settings-grid settings-grid-wide">
      <article class="card settings-card">
        <h3>Quick Reading</h3>
        <div class="insight-list">
          <div class="insight-row">
            <span class="subdued">Daily target</span>
            <strong>${formatHours(state.settings.dailyTargetMinutes / 60)}</strong>
          </div>
          <div class="insight-row">
            <span class="subdued">Focus cycle</span>
            <strong>${state.settings.focusMinutes}/${state.settings.shortBreakMinutes}/${state.settings.longBreakMinutes} min</strong>
          </div>
          <div class="insight-row">
            <span class="subdued">Long break cadence</span>
            <strong>Every ${state.settings.sessionsBeforeLongBreak} focus blocks</strong>
          </div>
          <div class="insight-row">
            <span class="subdued">Sound cues</span>
            <strong>${state.settings.soundEnabled ? "On" : "Off"}</strong>
          </div>
        </div>
      </article>

      <article class="card settings-card">
        <h3>Sound Cues</h3>
        <div class="setting-group">
          <label class="toggle-row" for="soundEnabled">
            <span>Play Pomodoro milestone sounds</span>
            <input id="soundEnabled" type="checkbox" data-setting-boolean="soundEnabled" ${state.settings.soundEnabled ? "checked" : ""}>
          </label>
        </div>
        <p class="setting-help">You can keep them on for live Pomodoro feedback, or switch them off if you want a silent study setup.</p>
        <div class="sound-preview-list">
          <div class="sound-preview-row">
            <div>
              <strong>Focus start</strong>
              <p class="setting-help">Plays when a focus block begins.</p>
            </div>
            <button class="button button-secondary" data-action="preview-focus-start">Preview</button>
          </div>
          <div class="sound-preview-row">
            <div>
              <strong>Break start</strong>
              <p class="setting-help">Plays when a break begins.</p>
            </div>
            <button class="button button-secondary" data-action="preview-break-start">Preview</button>
          </div>
          <div class="sound-preview-row">
            <div>
              <strong>Focus complete</strong>
              <p class="setting-help">Warm chime when a focus block ends.</p>
            </div>
            <button class="button button-secondary" data-action="preview-focus-complete">Preview</button>
          </div>
          <div class="sound-preview-row">
            <div>
              <strong>Daily target hit</strong>
              <p class="setting-help">Success cue when you cross your target for the day.</p>
            </div>
            <button class="button button-secondary" data-action="preview-target-hit">Preview</button>
          </div>
        </div>
        <div class="button-row settings-actions">
          <button class="button button-secondary" data-action="preview-sound">Quick Preview</button>
        </div>
      </article>
    </section>

    <p class="footer-note">Bar Exam 2026 Command Center web edition. Data is stored in this browser using local storage.</p>
  `;
}

function renderTargetCard(data) {
  const ratio = Math.min(completionRatio(data.today), 1);
  return `
    <article class="card stat-card">
      <h3>Today's Study Target</h3>
      <div class="big-number">${formatHours(data.today.totalHours)} / ${formatHours(state.settings.dailyTargetMinutes / 60)}</div>
      <div class="progress-track"><div class="progress-fill" style="width:${Math.round(ratio * 100)}%;"></div></div>
      <p class="subdued">${data.goodDays} good days • ${data.weakerDays} rescue days • ${data.bestStreak} day streak</p>
    </article>
  `;
}

function renderSyllabusCoverageCard(data) {
  return `
    <article class="card stat-card">
      <h3>Syllabus Coverage</h3>
      <div class="big-number">${Math.round(data.syllabusRatio * 100)}%</div>
      <div class="progress-track"><div class="progress-fill" style="width:${Math.round(data.syllabusRatio * 100)}%;"></div></div>
      <p class="subdued">${data.examReadySections} sections marked exam-ready out of ${TOTAL_SECTIONS}</p>
    </article>
  `;
}

function renderScheduleItem(item) {
  return `
    <div class="schedule-item">
      <div class="schedule-top">
        <span>${item.label}</span>
        <span>${item.weight}</span>
      </div>
      <h4>${item.subject}</h4>
      <p class="subdued">${item.dateLabel} • ${item.sessionLabel}</p>
    </div>
  `;
}

function renderSubjectButton(subject) {
  const ratio = Math.round(subjectProgress(subject) * 100);
  const readyCount = subject.sections.filter((section) => statusFor(section.id).id === "examReady").length;
  const activeClass = subject.id === state.selectedSubjectId ? "is-active" : "";
  return `
    <button class="subject-button ${activeClass}" data-subject-id="${subject.id}">
      <div class="subject-button-top">
        <strong>${subject.title}</strong>
        <small>${subject.weight}</small>
      </div>
      <div class="progress-track">
        <div class="progress-fill" style="width:${ratio}%;"></div>
      </div>
      <small>${readyCount}/${subject.sections.length} exam-ready</small>
    </button>
  `;
}

function renderSectionRow(section) {
  const status = statusFor(section.id);
  return `
    <div class="section-row" style="--status-color:${status.color}; --status-soft:${status.soft};">
      <div>
        <strong>${section.title}</strong>
        <p class="section-note">${status.description}</p>
      </div>
      <div>
        <span class="status-badge"><span class="color-dot" style="background:${status.color};"></span>${status.title}</span>
        <select class="select" data-section-status="${section.id}">
          ${STATUS_META.map((option) => `
            <option value="${option.id}" ${option.id === status.id ? "selected" : ""}>${option.title}</option>
          `).join("")}
        </select>
      </div>
    </div>
  `;
}

function renderDailyChart(days, targetHours) {
  const width = 900;
  const height = 280;
  const paddingLeft = 46;
  const paddingBottom = 34;
  const paddingTop = 18;
  const paddingRight = 18;
  const innerWidth = width - paddingLeft - paddingRight;
  const innerHeight = height - paddingTop - paddingBottom;
  const maxValue = Math.max(targetHours, ...days.map((day) => day.totalHours), 1);
  const barWidth = innerWidth / Math.max(days.length, 1);
  const targetY = paddingTop + innerHeight - (targetHours / maxValue) * innerHeight;

  const bars = days.map((day, index) => {
    const valueHeight = (day.totalHours / maxValue) * innerHeight;
    const x = paddingLeft + index * barWidth + barWidth * 0.16;
    const y = paddingTop + innerHeight - valueHeight;
    const widthValue = Math.max(barWidth * 0.68, 8);
    const ratio = completionRatio(day);
    const fill = ratio >= 1
      ? "#45d483"
      : ratio >= 0.6
        ? "#ffbf47"
        : ratio > 0
          ? "#ff5d5d"
          : "rgba(255,255,255,0.16)";
    const label = formatMiniDate(day.dayStart);
    const labelX = x + widthValue / 2;

    return `
      <rect x="${x.toFixed(2)}" y="${y.toFixed(2)}" width="${widthValue.toFixed(2)}" height="${Math.max(valueHeight, 4).toFixed(2)}" rx="8" fill="${fill}" />
      ${days.length <= 16 || index % Math.ceil(days.length / 8) === 0
        ? `<text x="${labelX.toFixed(2)}" y="${height - 10}" text-anchor="middle" fill="#8fa0b8" font-size="12">${label}</text>`
        : ""}
    `;
  }).join("");

  const yTicks = [0, maxValue / 2, maxValue].map((value) => {
    const y = paddingTop + innerHeight - (value / maxValue) * innerHeight;
    return `
      <line x1="${paddingLeft}" x2="${width - paddingRight}" y1="${y.toFixed(2)}" y2="${y.toFixed(2)}" stroke="rgba(255,255,255,0.08)" stroke-dasharray="4 6" />
      <text x="10" y="${(y + 4).toFixed(2)}" fill="#8fa0b8" font-size="12">${value.toFixed(1)}h</text>
    `;
  }).join("");

  return `
    <svg viewBox="0 0 ${width} ${height}" role="img" aria-label="Daily study hours chart">
      ${yTicks}
      <line x1="${paddingLeft}" x2="${width - paddingRight}" y1="${targetY.toFixed(2)}" y2="${targetY.toFixed(2)}" stroke="#ffcb67" stroke-width="2" stroke-dasharray="8 8" />
      <text x="${width - paddingRight - 8}" y="${(targetY - 8).toFixed(2)}" text-anchor="end" fill="#ffcb67" font-size="12">Target</text>
      ${bars}
    </svg>
  `;
}

function renderWeekdayChart(days) {
  const width = 760;
  const height = 250;
  const paddingLeft = 28;
  const paddingBottom = 34;
  const paddingTop = 16;
  const paddingRight = 18;
  const innerWidth = width - paddingLeft - paddingRight;
  const innerHeight = height - paddingTop - paddingBottom;
  const maxValue = Math.max(...days.map((day) => day.averageHours), 1);
  const barWidth = innerWidth / Math.max(days.length, 1);

  const bars = days.map((day, index) => {
    const valueHeight = (day.averageHours / maxValue) * innerHeight;
    const x = paddingLeft + index * barWidth + barWidth * 0.2;
    const y = paddingTop + innerHeight - valueHeight;
    const widthValue = Math.max(barWidth * 0.6, 12);
    return `
      <rect x="${x.toFixed(2)}" y="${y.toFixed(2)}" width="${widthValue.toFixed(2)}" height="${Math.max(valueHeight, 4).toFixed(2)}" rx="8" fill="#55a6ff" />
      <text x="${(x + widthValue / 2).toFixed(2)}" y="${height - 10}" text-anchor="middle" fill="#8fa0b8" font-size="12">${day.label}</text>
    `;
  }).join("");

  return `
    <svg viewBox="0 0 ${width} ${height}" role="img" aria-label="Average study hours by weekday">
      <line x1="${paddingLeft}" x2="${width - paddingRight}" y1="${paddingTop + innerHeight}" y2="${paddingTop + innerHeight}" stroke="rgba(255,255,255,0.10)" />
      ${bars}
    </svg>
  `;
}

function subjectProgress(subject) {
  const total = subject.sections.reduce((sum, section) => sum + statusFor(section.id).progressScore, 0);
  return total / subject.sections.length;
}

function pdfURLForSubject(subject) {
  return `./assets/2026-Bar-Bulletin.pdf#page=${subject.bulletinPageRange[0]}`;
}

function countdownText() {
  const now = Date.now();
  const diffMs = Math.max(EXAM_START.getTime() - now, 0);
  const days = Math.max(Math.ceil(diffMs / 86400000), 0);
  const exactDays = Math.floor(diffMs / 86400000);
  const hours = Math.floor((diffMs % 86400000) / 3600000);
  const minutes = Math.floor((diffMs % 3600000) / 60000);
  const seconds = Math.floor((diffMs % 60000) / 1000);

  const detailFormatter = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Manila",
    month: "long",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });

  return {
    daysLabel: `${days} ${days === 1 ? "day" : "days"} left`,
    detailLabel: `${detailFormatter.format(EXAM_START)} Manila time • Exact countdown: ${exactDays}d ${pad(hours)}h ${pad(minutes)}m ${pad(seconds)}s`,
    sideLabel: `${detailFormatter.format(EXAM_START)} Manila time`,
  };
}

function updateCountdownUI() {
  const countdown = countdownText();
  for (const id of ["countdown-days-side", "countdown-days-top"]) {
    const node = document.getElementById(id);
    if (node) {
      node.textContent = countdown.daysLabel;
    }
  }
  const sideNode = document.getElementById("countdown-detail-side");
  if (sideNode) {
    sideNode.textContent = countdown.sideLabel;
  }
  const topNode = document.getElementById("countdown-detail-top");
  if (topNode) {
    topNode.textContent = countdown.detailLabel;
  }
}

function updateTimerUI() {
  if (!state.timer.isRunning || !state.timer.endsAt) {
    const clock = document.getElementById("timer-clock");
    const phase = document.getElementById("timer-phase");
    const note = document.getElementById("timer-note");
    if (clock) {
      clock.textContent = formatClock(state.timer.remainingSeconds);
    }
    if (phase) {
      phase.textContent = PHASE_META[state.timer.phase].title;
    }
    if (note) {
      note.textContent = PHASE_META[state.timer.phase].description;
    }
    return;
  }

  const remaining = Math.max(1, Math.ceil((new Date(state.timer.endsAt).getTime() - Date.now()) / 1000));
  state.timer.remainingSeconds = remaining;
  saveTimer();

  const clock = document.getElementById("timer-clock");
  const phase = document.getElementById("timer-phase");
  const note = document.getElementById("timer-note");
  if (clock) {
    clock.textContent = formatClock(remaining);
  }
  if (phase) {
    phase.textContent = PHASE_META[state.timer.phase].title;
  }
  if (note) {
    note.textContent = PHASE_META[state.timer.phase].description;
  }
}

function formatClock(totalSeconds) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${pad(minutes)}:${pad(seconds)}`;
}

function pad(value) {
  return String(value).padStart(2, "0");
}

function formatHours(hours) {
  return `${hours.toFixed(1)} hrs`;
}

function formatShortDate(date) {
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric" }).format(date);
}

function formatMiniDate(date) {
  return new Intl.DateTimeFormat("en-US", { month: "numeric", day: "numeric" }).format(date);
}

function escapeAttribute(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("\"", "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function createSoundEngine() {
  let audioContext = null;

  function getContext() {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioContextClass) {
      return null;
    }

    if (!audioContext) {
      audioContext = new AudioContextClass();
    }

    return audioContext;
  }

  function arm() {
    const context = getContext();
    if (!context) {
      return;
    }

    if (context.state === "suspended") {
      context.resume().catch(() => {});
    }
  }

  function playPattern(pattern, delayMs = 0) {
    const context = getContext();
    if (!context || context.state === "suspended") {
      return;
    }

    const startAt = context.currentTime + 0.02 + delayMs / 1000;

    pattern.forEach((note) => {
      const oscillator = context.createOscillator();
      const gain = context.createGain();
      oscillator.type = note.type ?? "sine";
      oscillator.frequency.setValueAtTime(note.frequency, startAt + note.offset);
      gain.gain.setValueAtTime(0.0001, startAt + note.offset);
      gain.gain.exponentialRampToValueAtTime(note.gain ?? 0.045, startAt + note.offset + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, startAt + note.offset + note.duration);
      oscillator.connect(gain);
      gain.connect(context.destination);
      oscillator.start(startAt + note.offset);
      oscillator.stop(startAt + note.offset + note.duration + 0.03);
    });
  }

  return {
    arm,
    preview() {
      arm();
      playPattern([
        { frequency: 392.0, offset: 0, duration: 0.12, gain: 0.03, type: "triangle" },
        { frequency: 523.25, offset: 0.08, duration: 0.16, gain: 0.036, type: "triangle" },
        { frequency: 659.25, offset: 0.18, duration: 0.22, gain: 0.04, type: "sine" },
      ]);
    },
    playFocusStart(delayMs = 0) {
      arm();
      playPattern([
        { frequency: 392.0, offset: 0, duration: 0.12, gain: 0.03, type: "triangle" },
        { frequency: 523.25, offset: 0.08, duration: 0.16, gain: 0.036, type: "triangle" },
        { frequency: 659.25, offset: 0.18, duration: 0.22, gain: 0.04, type: "sine" },
      ], delayMs);
    },
    playBreakStart(delayMs = 0) {
      arm();
      playPattern([
        { frequency: 493.88, offset: 0, duration: 0.1, gain: 0.02, type: "sine" },
        { frequency: 587.33, offset: 0.08, duration: 0.14, gain: 0.024, type: "triangle" },
      ], delayMs);
    },
    playFocusComplete(isLongBreak) {
      arm();
      playPattern(
        isLongBreak
          ? [
              { frequency: 523.25, offset: 0, duration: 0.30, gain: 0.05, type: "triangle" },
              { frequency: 659.25, offset: 0.18, duration: 0.32, gain: 0.045, type: "triangle" },
              { frequency: 783.99, offset: 0.36, duration: 0.46, gain: 0.04, type: "sine" },
            ]
          : [
              { frequency: 587.33, offset: 0, duration: 0.24, gain: 0.045, type: "triangle" },
              { frequency: 698.46, offset: 0.12, duration: 0.30, gain: 0.04, type: "sine" },
            ],
      );
    },
    playBreakComplete(isLongBreak) {
      arm();
      playPattern(
        isLongBreak
          ? [
              { frequency: 493.88, offset: 0, duration: 0.20, gain: 0.04, type: "sine" },
              { frequency: 659.25, offset: 0.14, duration: 0.26, gain: 0.032, type: "triangle" },
            ]
          : [
              { frequency: 783.99, offset: 0, duration: 0.16, gain: 0.03, type: "sine" },
              { frequency: 1046.5, offset: 0.1, duration: 0.18, gain: 0.02, type: "sine" },
            ],
      );
    },
    playTargetHit() {
      arm();
      playPattern([
        { frequency: 523.25, offset: 0, duration: 0.22, gain: 0.045, type: "triangle" },
        { frequency: 659.25, offset: 0.12, duration: 0.24, gain: 0.04, type: "triangle" },
        { frequency: 783.99, offset: 0.24, duration: 0.28, gain: 0.04, type: "sine" },
        { frequency: 1046.5, offset: 0.36, duration: 0.40, gain: 0.035, type: "sine" },
      ]);
    },
  };
}

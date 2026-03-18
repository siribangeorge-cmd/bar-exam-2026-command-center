import Foundation
import SwiftUI

struct StoredAppSettings: Codable, Sendable, Equatable {
    var dailyTargetMinutes: Int = 6 * 60
    var focusMinutes: Int = 50
    var shortBreakMinutes: Int = 10
    var longBreakMinutes: Int = 25
    var sessionsBeforeLongBreak: Int = 4

    static let `default` = StoredAppSettings()

    var dailyTargetHoursText: String {
        String(format: "%.1f", Double(dailyTargetMinutes) / 60.0)
    }

    func normalized() -> StoredAppSettings {
        StoredAppSettings(
            dailyTargetMinutes: max(dailyTargetMinutes, 30),
            focusMinutes: max(focusMinutes, 5),
            shortBreakMinutes: max(shortBreakMinutes, 1),
            longBreakMinutes: max(longBreakMinutes, 5),
            sessionsBeforeLongBreak: max(sessionsBeforeLongBreak, 2)
        )
    }
}

enum SyllabusStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case notStarted
    case needsReview
    case inProgress
    case secondPass
    case examReady
    case onHold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notStarted:
            return "Not started"
        case .needsReview:
            return "Needs more review"
        case .inProgress:
            return "In progress"
        case .secondPass:
            return "Second pass"
        case .examReady:
            return "Exam ready"
        case .onHold:
            return "On hold"
        }
    }

    var shortTitle: String {
        switch self {
        case .notStarted:
            return "Red"
        case .needsReview:
            return "Rose"
        case .inProgress:
            return "Amber"
        case .secondPass:
            return "Blue"
        case .examReady:
            return "Green"
        case .onHold:
            return "Gray"
        }
    }

    var description: String {
        switch self {
        case .notStarted:
            return "You have not touched this section yet."
        case .needsReview:
            return "You covered it once, but it still feels shaky."
        case .inProgress:
            return "This section is actively in your current rotation."
        case .secondPass:
            return "You are already doing recall and memory work here."
        case .examReady:
            return "This section feels solid and ready for bar-level recall."
        case .onHold:
            return "Temporarily parked while other sections get priority."
        }
    }

    var tint: Color {
        switch self {
        case .notStarted:
            return Color(red: 0.77, green: 0.19, blue: 0.20)
        case .needsReview:
            return Color(red: 0.90, green: 0.46, blue: 0.47)
        case .inProgress:
            return Color(red: 0.85, green: 0.60, blue: 0.18)
        case .secondPass:
            return Color(red: 0.19, green: 0.45, blue: 0.74)
        case .examReady:
            return Color(red: 0.19, green: 0.58, blue: 0.35)
        case .onHold:
            return Color(red: 0.47, green: 0.50, blue: 0.56)
        }
    }

    var progressScore: Double {
        switch self {
        case .notStarted:
            return 0
        case .needsReview:
            return 0.3
        case .inProgress:
            return 0.55
        case .secondPass:
            return 0.8
        case .examReady:
            return 1
        case .onHold:
            return 0.12
        }
    }
}

struct SyllabusSection: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
}

struct SyllabusSubject: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let weight: String
    let examWindow: String
    let examDay: String
    let bulletinPageRange: ClosedRange<Int>
    let summary: String
    let sections: [SyllabusSection]

    var startPage: Int {
        bulletinPageRange.lowerBound
    }

    var pageLabel: String {
        "Bulletin pages \(bulletinPageRange.lowerBound)-\(bulletinPageRange.upperBound)"
    }
}

struct BarExamScheduleItem: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let dateLabel: String
    let sessionLabel: String
    let subject: String
    let weight: String
}

enum SyllabusCatalog {
    static let examSchedule: [BarExamScheduleItem] = [
        BarExamScheduleItem(
            id: "day1-am",
            label: "Day 1",
            dateLabel: "September 6, 2026",
            sessionLabel: "8:00 AM - 12:00 PM",
            subject: "Political and Public International Law",
            weight: "15%"
        ),
        BarExamScheduleItem(
            id: "day1-pm",
            label: "Day 1",
            dateLabel: "September 6, 2026",
            sessionLabel: "2:00 PM - 6:00 PM",
            subject: "Commercial and Taxation Laws",
            weight: "20%"
        ),
        BarExamScheduleItem(
            id: "day2-am",
            label: "Day 2",
            dateLabel: "September 9, 2026",
            sessionLabel: "8:00 AM - 12:00 PM",
            subject: "Civil Law and Land Titles and Deeds",
            weight: "20%"
        ),
        BarExamScheduleItem(
            id: "day2-pm",
            label: "Day 2",
            dateLabel: "September 9, 2026",
            sessionLabel: "2:00 PM - 6:00 PM",
            subject: "Labor and Social Legislation",
            weight: "10%"
        ),
        BarExamScheduleItem(
            id: "day3-am",
            label: "Day 3",
            dateLabel: "September 13, 2026",
            sessionLabel: "8:00 AM - 12:00 PM",
            subject: "Criminal Law",
            weight: "10%"
        ),
        BarExamScheduleItem(
            id: "day3-pm",
            label: "Day 3",
            dateLabel: "September 13, 2026",
            sessionLabel: "2:00 PM - 6:00 PM",
            subject: "Remedial Law, Legal and Judicial Ethics, with Practical Exercises",
            weight: "25%"
        ),
    ]

    static let subjects: [SyllabusSubject] = [
        SyllabusSubject(
            id: "political-public-international-law",
            title: "Political and Public International Law",
            weight: "15%",
            examWindow: "Day 1 • Morning",
            examDay: "September 6, 2026",
            bulletinPageRange: 6...14,
            summary: "Constitutional structure, rights, public officers, election law, local governments, and public international law.",
            sections: [
                SyllabusSection(id: "pol-basic-concepts", title: "Basic Concepts"),
                SyllabusSection(id: "pol-national-territory", title: "National Territory"),
                SyllabusSection(id: "pol-citizenship", title: "Citizenship"),
                SyllabusSection(id: "pol-legislative", title: "Legislative Department"),
                SyllabusSection(id: "pol-executive", title: "Executive Department"),
                SyllabusSection(id: "pol-judicial", title: "Judicial Department"),
                SyllabusSection(id: "pol-constitutional-commissions", title: "Constitutional Commissions"),
                SyllabusSection(id: "pol-constitutional-rights", title: "Constitutional Rights"),
                SyllabusSection(id: "pol-social-justice", title: "Social Justice and Human Rights"),
                SyllabusSection(id: "pol-academic-freedom", title: "Academic Freedom"),
                SyllabusSection(id: "pol-national-economy", title: "National Economy and Patrimony"),
                SyllabusSection(id: "pol-administrative-law", title: "Administrative Law"),
                SyllabusSection(id: "pol-public-officers", title: "Law on Public Officers"),
                SyllabusSection(id: "pol-election-law", title: "Election Law"),
                SyllabusSection(id: "pol-local-governments", title: "Local Governments"),
                SyllabusSection(id: "pol-public-international-law", title: "Public International Law"),
            ]
        ),
        SyllabusSubject(
            id: "commercial-taxation-laws",
            title: "Commercial and Taxation Laws",
            weight: "20%",
            examWindow: "Day 1 • Afternoon",
            examDay: "September 6, 2026",
            bulletinPageRange: 15...24,
            summary: "Corporations, insurance, banking, intellectual property, special commercial statutes, and core tax rules and remedies.",
            sections: [
                SyllabusSection(id: "comm-business-organizations", title: "Business Organizations"),
                SyllabusSection(id: "comm-insurance", title: "Insurance"),
                SyllabusSection(id: "comm-transportation", title: "Transportation"),
                SyllabusSection(id: "comm-banking", title: "Banking"),
                SyllabusSection(id: "comm-intellectual-property", title: "Intellectual Property"),
                SyllabusSection(id: "comm-special-commercial-laws", title: "Special Commercial Laws"),
                SyllabusSection(id: "comm-taxation-law", title: "Taxation Law"),
            ]
        ),
        SyllabusSubject(
            id: "civil-law-land-titles",
            title: "Civil Law and Land Titles and Deeds",
            weight: "20%",
            examWindow: "Day 2 • Morning",
            examDay: "September 9, 2026",
            bulletinPageRange: 25...33,
            summary: "Civil code foundations, family law, property, land titles, succession, obligations, contracts, quasi-delicts, and damages.",
            sections: [
                SyllabusSection(id: "civil-effect-application", title: "Effect and Application of Laws"),
                SyllabusSection(id: "civil-persons", title: "Persons"),
                SyllabusSection(id: "civil-family-relations", title: "Family Relations"),
                SyllabusSection(id: "civil-civil-register", title: "Civil Register"),
                SyllabusSection(id: "civil-property", title: "Property, Ownership, and its Modifications"),
                SyllabusSection(id: "civil-land-titles", title: "Land Titles and Deeds"),
                SyllabusSection(id: "civil-succession", title: "Succession"),
                SyllabusSection(id: "civil-obligations-contracts", title: "Obligations and Contracts"),
                SyllabusSection(id: "civil-special-contracts", title: "Special Contracts"),
                SyllabusSection(id: "civil-quasi-contracts", title: "Quasi-Contracts"),
                SyllabusSection(id: "civil-torts", title: "Torts and Quasi-Delicts"),
                SyllabusSection(id: "civil-damages", title: "Damages"),
            ]
        ),
        SyllabusSubject(
            id: "labor-social-legislation",
            title: "Labor and Social Legislation",
            weight: "10%",
            examWindow: "Day 2 • Afternoon",
            examDay: "September 9, 2026",
            bulletinPageRange: 34...41,
            summary: "Labor policies, recruitment, employment relationship, labor standards, labor relations, termination, social legislation, and remedies.",
            sections: [
                SyllabusSection(id: "labor-basic-principles", title: "Basic Principles and Concepts"),
                SyllabusSection(id: "labor-recruitment", title: "Recruitment and Placement"),
                SyllabusSection(id: "labor-employment-relationship", title: "Employment Relationship"),
                SyllabusSection(id: "labor-standards", title: "Labor Standards"),
                SyllabusSection(id: "labor-relations", title: "Labor Relations"),
                SyllabusSection(id: "labor-suspension-termination", title: "Suspension and Termination of Employment"),
                SyllabusSection(id: "labor-social-legislation", title: "Social Legislation"),
                SyllabusSection(id: "labor-adjudication", title: "Labor Adjudication: Jurisdiction and Remedies"),
            ]
        ),
        SyllabusSubject(
            id: "criminal-law",
            title: "Criminal Law",
            weight: "10%",
            examWindow: "Day 3 • Morning",
            examDay: "September 13, 2026",
            bulletinPageRange: 42...46,
            summary: "Fundamental penal principles, criminal liability, penalties, extinction of liability, and the special laws integrated into Book II crimes.",
            sections: [
                SyllabusSection(id: "crim-fundamental-principles", title: "Fundamental Principles"),
                SyllabusSection(id: "crim-felonies-liability", title: "Felonies and Criminal Liability"),
                SyllabusSection(id: "crim-crimes-penalties", title: "Crimes and Their Penalties"),
            ]
        ),
        SyllabusSubject(
            id: "remedial-ethics-practical",
            title: "Remedial Law, Legal and Judicial Ethics, with Practical Exercises",
            weight: "25%",
            examWindow: "Day 3 • Afternoon",
            examDay: "September 13, 2026",
            bulletinPageRange: 47...62,
            summary: "Procedure, evidence, writs, remedies, ethics, and bar-style drafting tasks.",
            sections: [
                SyllabusSection(id: "rem-general-principles", title: "General Principles"),
                SyllabusSection(id: "rem-jurisdiction", title: "Jurisdiction"),
                SyllabusSection(id: "rem-civil-procedure", title: "Civil Procedure"),
                SyllabusSection(id: "rem-provisional-remedies", title: "Provisional Remedies"),
                SyllabusSection(id: "rem-special-civil-actions", title: "Special Civil Actions"),
                SyllabusSection(id: "rem-special-proceedings", title: "Special Proceedings and Writs"),
                SyllabusSection(id: "rem-criminal-procedure", title: "Criminal Procedure"),
                SyllabusSection(id: "rem-evidence", title: "Evidence"),
                SyllabusSection(id: "rem-legal-judicial-ethics", title: "Legal and Judicial Ethics"),
                SyllabusSection(id: "rem-practical-exercises", title: "Practical Exercises"),
            ]
        ),
    ]

    static let totalSections: Int = subjects.reduce(into: 0) { total, subject in
        total += subject.sections.count
    }
}

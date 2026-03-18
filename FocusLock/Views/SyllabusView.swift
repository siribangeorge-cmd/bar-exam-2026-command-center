import PDFKit
import SwiftUI

struct SyllabusView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HSplitView {
            subjectSidebar
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 340)

            if let subject = model.selectedSubject {
                subjectDetail(for: subject)
                    .frame(minWidth: 520)

                bulletinPreview(for: subject)
                    .frame(minWidth: 420)
            } else {
                Text("Choose a subject to begin.")
                    .foregroundStyle(CommandCenterTheme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
        .navigationTitle("Syllabus")
        .commandCenterBackground()
    }

    private var subjectSidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Subjects")
                .font(.title2.weight(.bold))

            Text("Each subject is linked to its page range inside your Bar Bulletin.")
                .font(.callout)
                .foregroundStyle(CommandCenterTheme.muted)

            List(model.subjects, selection: Binding(
                get: { Optional(model.selectedSubjectID) },
                set: { model.setSelectedSubject($0 ?? model.selectedSubjectID) }
            )) { subject in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(subject.title)
                            .font(.body.weight(.semibold))
                        Spacer()
                        Text(subject.weight)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CommandCenterTheme.muted)
                    }

                    ProgressView(value: model.progressRatio(for: subject))
                        .tint(CommandCenterTheme.accent)

                    Text("\(model.readyCount(for: subject))/\(subject.sections.count) exam-ready")
                        .font(.caption)
                        .foregroundStyle(CommandCenterTheme.muted)
                }
                .padding(.vertical, 6)
                .tag(subject.id)
            }
            .listStyle(.sidebar)
        }
        .commandCenterCard()
    }

    private func subjectDetail(for subject: SyllabusSubject) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(subject.title)
                    .font(.system(size: 30, weight: .bold, design: .serif))

                Text("\(subject.examWindow) • \(subject.examDay)")
                    .font(.headline)
                    .foregroundStyle(CommandCenterTheme.warmAccent)

                Text(subject.summary)
                    .font(.callout)
                    .foregroundStyle(CommandCenterTheme.muted)
            }

            HStack {
                TextField("Filter sections", text: $model.searchText)
                    .textFieldStyle(.roundedBorder)

                Text(subject.pageLabel)
                    .font(.callout)
                    .foregroundStyle(CommandCenterTheme.muted)
            }

            legendGrid

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.filteredSections(for: subject)) { section in
                        sectionRow(section)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .commandCenterCard()
    }

    private var legendGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(SyllabusStatus.allCases) { status in
                HStack(spacing: 8) {
                    Circle()
                        .fill(status.tint)
                        .frame(width: 10, height: 10)
                    Text(status.shortTitle)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(status.tint.opacity(0.12))
                )
            }
        }
    }

    private func sectionRow(_ section: SyllabusSection) -> some View {
        let status = model.status(for: section.id)

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(section.title)
                    .font(.headline)
                Text(status.description)
                    .font(.caption)
                    .foregroundStyle(CommandCenterTheme.muted)
            }

            Spacer()

            Menu {
                ForEach(SyllabusStatus.allCases) { option in
                    Button {
                        model.setSyllabusStatus(option, for: section.id)
                    } label: {
                        Label(option.title, systemImage: option == status ? "checkmark.circle.fill" : "circle")
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(status.tint)
                        .frame(width: 10, height: 10)
                    Text(status.title)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(status.tint.opacity(0.16))
                )
            }
            .menuStyle(.borderlessButton)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(status.tint.opacity(0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(status.tint.opacity(0.25), lineWidth: 1)
        )
    }

    private func bulletinPreview(for subject: SyllabusSubject) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Bulletin PDF", systemImage: "doc.richtext")
                .font(.headline)

            Text("The preview jumps to the official syllabus pages for the subject you selected.")
                .font(.callout)
                .foregroundStyle(CommandCenterTheme.muted)

            BulletinPDFView(url: model.bulletinURL, pageNumber: subject.startPage)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .commandCenterCard()
    }
}

struct BulletinPDFView: NSViewRepresentable {
    let url: URL?
    let pageNumber: Int

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        return view
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if pdfView.document == nil, let url {
            pdfView.document = PDFDocument(url: url)
        }

        if let page = pdfView.document?.page(at: max(pageNumber - 1, 0)) {
            pdfView.go(to: page)
        }
    }
}

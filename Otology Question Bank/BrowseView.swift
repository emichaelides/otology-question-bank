import SwiftUI

struct BrowseView: View {
    @EnvironmentObject private var engine: QuizEngine
    @State private var selectedQuestion: Question?
    @State private var searchText = ""

    private var categoriesWithQuestions: [(category: String, questions: [Question])] {
        let filtered = searchText.isEmpty
            ? engine.questions
            : engine.questions.filter {
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        return engine.allCategories.compactMap { category in
            let qs = filtered.filter { $0.category == category }
            return qs.isEmpty ? nil : (category: category, questions: qs)
        }
    }

    var body: some View {
        List {
            ForEach(categoriesWithQuestions, id: \.category) { section in
                Section(header: categoryHeader(section.category, count: section.questions.count)) {
                    ForEach(section.questions) { question in
                        BrowseRow(question: question)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedQuestion = question }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Browse")
        .searchable(text: $searchText, prompt: "Search questions…")
        .sheet(item: $selectedQuestion) { question in
            QuestionDetailView(question: question)
        }
    }

    private func categoryHeader(_ name: String, count: Int) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text("\(count) Q")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Browse Row

struct BrowseRow: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question.question)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)
            difficultyBadge
        }
        .padding(.vertical, 2)
    }

    private var difficultyBadge: some View {
        let (label, color): (String, Color) = switch question.difficulty {
        case "easy":   ("Easy",   .green)
        case "medium": ("Medium", .orange)
        case "hard":   ("Hard",   .red)
        default:       (question.difficulty.capitalized, .gray)
        }
        return Text(label)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    BrowseView()
        .environmentObject(QuizEngine())
}

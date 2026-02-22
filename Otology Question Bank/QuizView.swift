import SwiftUI

private enum AnswerState {
    case unanswered
    case answered(selectedIndex: Int)
}

struct QuizView: View {
    @EnvironmentObject private var engine: QuizEngine
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var answerState: AnswerState = .unanswered
    @State private var showSummary = false
    @State private var showSetup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    sessionProgressHeader
                    questionCard
                    choicesSection
                    if case .answered = answerState {
                        explanationCard
                        nextButton
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Home") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSetup = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            if engine.activeCategories.count < engine.allCategories.count ||
                               engine.activeDifficulties.count < 3 {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isAnswered)
            .fullScreenCover(isPresented: $showSummary) {
                SessionSummaryView(entries: engine.sessionEntries) {
                    showSummary = false
                    answerState = .unanswered
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showSetup = true
                    }
                }
                .environmentObject(engine)
            }
            .sheet(isPresented: $showSetup) {
                SessionSetupView()
                    .environmentObject(engine)
            }
            .onAppear {
                if !hasLaunchedBefore {
                    hasLaunchedBefore = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSetup = true
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var sessionProgressHeader: some View {
        let answered = engine.sessionEntries.count
        let total = engine.sessionLength
        let progress = Double(answered) / Double(total)
        return VStack(spacing: 6) {
            HStack {
                Text("Question \(isAnswered ? answered : answered + 1) of \(total)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                let correct = engine.sessionEntries.filter(\.wasCorrect).count
                if answered > 0 {
                    Text("\(correct)/\(answered) correct")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: progress)
                .tint(.accentColor)
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(engine.currentQuestion.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                difficultyBadge
            }
            Text(engine.currentQuestion.question)
                .font(.body)
                .fontWeight(.medium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    private var difficultyBadge: some View {
        let (label, color): (String, Color) = switch engine.currentQuestion.difficulty {
        case "easy":   ("Easy",   .green)
        case "medium": ("Medium", .orange)
        case "hard":   ("Hard",   .red)
        default:       (engine.currentQuestion.difficulty.capitalized, .gray)
        }
        return Text(label)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var choicesSection: some View {
        VStack(spacing: 10) {
            ForEach(engine.currentQuestion.choices.indices, id: \.self) { index in
                ChoiceButton(
                    label: engine.currentQuestion.choices[index],
                    state: choiceButtonState(for: index),
                    action: { handleAnswer(index) }
                )
            }
        }
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explanation")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(engine.currentQuestion.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var nextButton: some View {
        let isLast = engine.sessionEntries.count >= engine.sessionLength
        return Button {
            if isLast {
                Task { await FirestoreSync.uploadSession(engine: engine) }
                showSummary = true
            } else {
                answerState = .unanswered
                engine.nextQuestion()
            }
        } label: {
            Text(isLast ? "Finish Session" : "Next Question")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private var isAnswered: Bool {
        if case .answered = answerState { return true }
        return false
    }

    private func choiceButtonState(for index: Int) -> ChoiceButtonState {
        guard case .answered(let selected) = answerState else { return .normal }
        let correct = engine.currentQuestion.correctIndex
        if index == correct { return .correct }
        if index == selected { return .incorrect }
        return .normal
    }

    private func handleAnswer(_ index: Int) {
        guard case .unanswered = answerState else { return }
        engine.answer(index: index)
        answerState = .answered(selectedIndex: index)
    }
}

// MARK: - Choice Button

enum ChoiceButtonState { case normal, correct, incorrect }

struct ChoiceButton: View {
    let label: String
    let state: ChoiceButtonState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if state != .normal {
                    Image(systemName: state == .correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(state == .correct ? Color.green : Color.red)
                }
            }
            .padding()
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: state == .normal ? 0 : 2)
            )
        }
        .disabled(state != .normal)
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch state {
        case .normal:    return Color(.secondarySystemGroupedBackground)
        case .correct:   return Color.green.opacity(0.15)
        case .incorrect: return Color.red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .normal:    return .primary
        case .correct:   return .green
        case .incorrect: return .red
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:    return .clear
        case .correct:   return .green
        case .incorrect: return .red
        }
    }
}

#Preview {
    QuizView()
        .environmentObject(QuizEngine())
}

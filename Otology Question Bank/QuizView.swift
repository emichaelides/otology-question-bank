import SwiftUI

private enum AnswerState {
    case unanswered
    case answered(selectedIndex: Int)
}

struct QuizView: View {
    @EnvironmentObject private var engine: QuizEngine
    @State private var answerState: AnswerState = .unanswered

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
        .animation(.easeInOut(duration: 0.25), value: isAnswered)
    }

    // MARK: - Subviews

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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        Button {
            answerState = .unanswered
            engine.nextQuestion()
        } label: {
            Text("Next Question")
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

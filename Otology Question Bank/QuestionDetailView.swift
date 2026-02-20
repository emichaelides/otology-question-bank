import SwiftUI

struct QuestionDetailView: View {
    let question: Question
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    questionCard
                    choicesSection
                    explanationCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Question Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(question.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                difficultyBadge
            }
            Text(question.question)
                .font(.body)
                .fontWeight(.medium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var choicesSection: some View {
        VStack(spacing: 10) {
            ForEach(question.choices.indices, id: \.self) { index in
                let state: ChoiceButtonState = index == question.correctIndex ? .correct : .normal
                ChoiceButton(
                    label: question.choices[index],
                    state: state,
                    action: {}
                )
                .disabled(true)
            }
        }
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explanation")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(question.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    QuestionDetailView(question: Question(
        id: "PREVIEW",
        category: "Cochlear Implants",
        type: "single",
        difficulty: "medium",
        question: "What is the typical age threshold for cochlear implantation in children with bilateral profound sensorineural hearing loss?",
        choices: ["6 months", "12 months", "18 months", "24 months"],
        correctIndex: 1,
        explanation: "The FDA-approved age threshold for cochlear implantation is 12 months for children with bilateral profound sensorineural hearing loss."
    ))
}

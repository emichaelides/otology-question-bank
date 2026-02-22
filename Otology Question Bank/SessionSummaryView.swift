import SwiftUI
import FirebaseAuth

struct SessionSummaryView: View {
    let entries: [SessionEntry]
    let onNewSession: () -> Void

    @EnvironmentObject private var engine: QuizEngine
    @EnvironmentObject private var authManager: AuthManager

    private var correctCount: Int { entries.filter(\.wasCorrect).count }
    private var total: Int { entries.count }
    private var accuracy: Double { total > 0 ? Double(correctCount) / Double(total) : 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scoreCard
                    reviewList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Session", action: onNewSession)
                        .fontWeight(.semibold)
                }
            }
        }
        .task {
            await FirestoreSync.uploadSession(uid: authManager.user?.uid, engine: engine)
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 12)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: accuracy)
                    .stroke(accuracyColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: accuracy)
                VStack(spacing: 2) {
                    Text("\(correctCount)/\(total)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(accuracyColor)
                    Text("correct")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 32) {
                statPill(label: "Accuracy", value: "\(Int(accuracy * 100))%")
                statPill(label: "Correct", value: "\(correctCount)")
                statPill(label: "Missed", value: "\(total - correctCount)")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var accuracyColor: Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.5 { return .orange }
        return .red
    }

    // MARK: - Review List

    private var reviewList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(entries.indices, id: \.self) { i in
                ReviewRow(entry: entries[i], number: i + 1)
            }
        }
    }
}

// MARK: - Review Row

struct ReviewRow: View {
    let entry: SessionEntry
    let number: Int
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: entry.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(entry.wasCorrect ? .green : .red)
                        .font(.title3)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Q\(number). \(entry.question.question)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .lineLimit(expanded ? nil : 2)
                            .foregroundStyle(.primary)

                        if !entry.wasCorrect {
                            Text("Your answer: \(entry.question.choices[entry.selectedIndex])")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Text("Correct: \(entry.question.choices[entry.question.correctIndex])")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 3)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if expanded {
                Text(entry.question.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding([.horizontal, .bottom])
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SessionSummaryView(entries: []) {}
}

import SwiftUI
import FirebaseFirestore

private struct UserQuestionStat {
    let category: String
    let difficulty: String
    let attempts: Int
    let correct: Int
}

struct UserStatsView: View {
    let user: LeaderboardEntry

    @State private var questionStats: [UserQuestionStat] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                overallSection
                categorySection
                difficultySection
            }
        }
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.large)
        .task { await loadStats() }
    }

    // MARK: - Sections

    private var overallSection: some View {
        Section("Overall") {
            let totalAttempts = questionStats.reduce(0) { $0 + $1.attempts }
            let totalCorrect  = questionStats.reduce(0) { $0 + $1.correct }
            let accuracy = totalAttempts > 0 ? Double(totalCorrect) / Double(totalAttempts) : 0

            HStack {
                VStack(spacing: 4) {
                    Text("\(Int(accuracy * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(accuracyColor(accuracy))
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 4) {
                    Text("\(questionStats.filter { $0.attempts > 0 }.count)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("questions seen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
    }

    private var categorySection: some View {
        Section("By Category") {
            let categories = Array(Set(questionStats.map(\.category))).sorted()
            if categories.isEmpty {
                Text("No data").foregroundStyle(.secondary)
            } else {
                ForEach(categories, id: \.self) { category in
                    let stats    = questionStats.filter { $0.category == category }
                    let attempts = stats.reduce(0) { $0 + $1.attempts }
                    let correct  = stats.reduce(0) { $0 + $1.correct }
                    CategoryRow(name: category, questionCount: stats.count,
                                accuracy: attempts > 0 ? Double(correct) / Double(attempts) : nil)
                }
            }
        }
    }

    private var difficultySection: some View {
        Section("By Difficulty") {
            ForEach(["easy", "medium", "hard"], id: \.self) { diff in
                let stats    = questionStats.filter { $0.difficulty == diff }
                let attempts = stats.reduce(0) { $0 + $1.attempts }
                let correct  = stats.reduce(0) { $0 + $1.correct }
                CategoryRow(name: diff.capitalized, questionCount: stats.count,
                            accuracy: attempts > 0 ? Double(correct) / Double(attempts) : nil)
            }
        }
    }

    // MARK: - Data

    private func loadStats() async {
        isLoading = true
        do {
            let snapshot = try await db
                .collection("users").document(user.id)
                .collection("questionStats")
                .getDocuments()
            questionStats = snapshot.documents.compactMap { doc -> UserQuestionStat? in
                let data = doc.data()
                guard let category   = data["category"]   as? String,
                      let difficulty = data["difficulty"] as? String else { return nil }
                return UserQuestionStat(
                    category: category,
                    difficulty: difficulty,
                    attempts: data["attempts"] as? Int ?? 0,
                    correct:  data["correct"]  as? Int ?? 0
                )
            }
        } catch {
            print("[UserStatsView] Load failed: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func accuracyColor(_ value: Double) -> Color {
        if value >= 0.8 { return .green }
        if value >= 0.5 { return .orange }
        return .red
    }
}

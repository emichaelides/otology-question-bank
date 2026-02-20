import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var engine: QuizEngine
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                streakSection
                overallSection
                categorySection
                difficultySection
                resetSection
            }
            .navigationTitle("Progress")
            .confirmationDialog("Reset all stats?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { engine.resetStats() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear your accuracy history for all questions.")
            }
        }
    }

    // MARK: - Sections

    private var streakSection: some View {
        Section {
            HStack(spacing: 0) {
                streakPill(icon: "flame.fill", color: .orange,
                           value: engine.currentStreak, label: "Current Streak")
                Divider()
                streakPill(icon: "trophy.fill", color: .yellow,
                           value: engine.longestStreak, label: "Best Streak")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Streaks")
        }
    }

    private func streakPill(icon: String, color: Color, value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(value > 0 ? color : .secondary)
                Text("\(value)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(value > 0 ? color : .secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var overallSection: some View {
        Section("Overall") {
            let total = engine.questions.count
            let attempted = engine.stats.values.filter { $0.attempts > 0 }.count
            let totalAttempts = engine.stats.values.reduce(0) { $0 + $1.attempts }
            let totalCorrect = engine.stats.values.reduce(0) { $0 + $1.correct }
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
                    Text("\(attempted)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("of \(total) seen")
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
            let categories = Array(Set(engine.questions.map(\.category))).sorted()
            ForEach(categories, id: \.self) { category in
                let qs = engine.questions.filter { $0.category == category }
                let attempts = qs.reduce(0) { $0 + engine.statsFor($1.id).attempts }
                let correct = qs.reduce(0) { $0 + engine.statsFor($1.id).correct }
                let accuracy = attempts > 0 ? Double(correct) / Double(attempts) : nil
                CategoryRow(
                    name: category,
                    questionCount: qs.count,
                    accuracy: accuracy
                )
            }
        }
    }

    private var difficultySection: some View {
        Section("By Difficulty") {
            ForEach(["easy", "medium", "hard"], id: \.self) { diff in
                let qs = engine.questions.filter { $0.difficulty == diff }
                let attempts = qs.reduce(0) { $0 + engine.statsFor($1.id).attempts }
                let correct = qs.reduce(0) { $0 + engine.statsFor($1.id).correct }
                let accuracy = attempts > 0 ? Double(correct) / Double(attempts) : nil
                CategoryRow(
                    name: diff.capitalized,
                    questionCount: qs.count,
                    accuracy: accuracy
                )
            }
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset All Stats", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: - Helpers

    private func accuracyColor(_ value: Double) -> Color {
        if value >= 0.8 { return .green }
        if value >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let name: String
    let questionCount: Int
    let accuracy: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let accuracy {
                    Text("\(Int(accuracy * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(color(for: accuracy))
                } else {
                    Text("Not started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemFill))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color(for: accuracy ?? 0))
                            .frame(width: geo.size.width * (accuracy ?? 0), height: 6)
                    }
                }
                .frame(height: 6)
                Text("\(questionCount) Q")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }

    private func color(for value: Double) -> Color {
        if value >= 0.8 { return .green }
        if value >= 0.5 { return .orange }
        return .red
    }
}

#Preview {
    StatsView()
        .environmentObject(QuizEngine())
}

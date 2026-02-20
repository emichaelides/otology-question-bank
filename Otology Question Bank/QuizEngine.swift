import Foundation

// MARK: - Persistence helpers

private struct SessionPrefs: Codable {
    var activeCategories: [String]
    var activeDifficulties: [String]
    var sessionLength: Int
}

private struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
}

@MainActor
final class QuizEngine: ObservableObject {
    @Published private(set) var currentQuestion: Question
    @Published private(set) var sessionEntries: [SessionEntry] = []
    @Published private(set) var isSessionComplete = false

    let questions: [Question]

    // MARK: Filter state (persisted)
    @Published var activeCategories: Set<String>
    @Published var activeDifficulties: Set<String>
    @Published var sessionLength: Int

    // MARK: Streak (persisted)
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0

    // MARK: Stats
    @Published private(set) var stats: [String: QuestionStats]

    // MARK: UserDefaults keys
    private static let statsKey = "questionStats"
    private static let prefsKey = "sessionPrefs"
    private static let streakKey = "streakData"

    // MARK: Derived

    var allCategories: [String] {
        Array(Set(questions.map(\.category))).sorted()
    }

    var filteredQuestions: [Question] {
        questions.filter {
            activeCategories.contains($0.category) &&
            activeDifficulties.contains($0.difficulty)
        }
    }

    // MARK: Init

    init() {
        let loaded = Question.loadAll()
        let questions = loaded.isEmpty ? [
            Question(
                id: "PLACEHOLDER",
                category: "General",
                type: "general",
                difficulty: "easy",
                question: "No questions found in bundle.",
                choices: ["N/A", "N/A", "N/A", "N/A"],
                correctIndex: 0,
                explanation: "Add JSON question files to the Question Bank folder."
            )
        ] : loaded

        self.questions = questions

        // Load stats
        if let data = UserDefaults.standard.data(forKey: Self.statsKey),
           let decoded = try? JSONDecoder().decode([String: QuestionStats].self, from: data) {
            stats = decoded
        } else {
            stats = [:]
        }

        // Load prefs (default: all categories/difficulties on, length 10)
        let allCats = Array(Set(questions.map(\.category)))
        if let data = UserDefaults.standard.data(forKey: Self.prefsKey),
           let prefs = try? JSONDecoder().decode(SessionPrefs.self, from: data) {
            activeCategories = Set(prefs.activeCategories)
            activeDifficulties = Set(prefs.activeDifficulties)
            sessionLength = prefs.sessionLength
        } else {
            activeCategories = Set(allCats)
            activeDifficulties = ["easy", "medium", "hard"]
            sessionLength = 10
        }

        // Load streak
        if let data = UserDefaults.standard.data(forKey: Self.streakKey),
           let streak = try? JSONDecoder().decode(StreakData.self, from: data) {
            currentStreak = streak.currentStreak
            longestStreak = streak.longestStreak
        }

        currentQuestion = questions[0]
        nextQuestion()
    }

    // MARK: - Session actions

    func answer(index: Int) {
        var entry = stats[currentQuestion.id] ?? QuestionStats()
        entry.attempts += 1
        let correct = index == currentQuestion.correctIndex
        if correct {
            entry.correct += 1
            currentStreak += 1
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }
        stats[currentQuestion.id] = entry
        persistStats()
        persistStreak()
        sessionEntries.append(SessionEntry(question: currentQuestion, selectedIndex: index))
        if sessionEntries.count >= sessionLength {
            isSessionComplete = true
        }
    }

    func startNewSession() {
        sessionEntries = []
        isSessionComplete = false
        persistPrefs()
        nextQuestion()
    }

    func nextQuestion() {
        let pool = filteredQuestions.isEmpty ? questions : filteredQuestions
        let weights = pool.map { weight(for: $0) }
        let total = weights.reduce(0, +)
        var threshold = Double.random(in: 0..<total)
        for (question, w) in zip(pool, weights) {
            threshold -= w
            if threshold < 0 {
                currentQuestion = question
                return
            }
        }
        currentQuestion = pool.last!
    }

    // MARK: - Prefs

    func persistPrefs() {
        let prefs = SessionPrefs(
            activeCategories: Array(activeCategories),
            activeDifficulties: Array(activeDifficulties),
            sessionLength: sessionLength
        )
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: Self.prefsKey)
        }
    }

    // MARK: - Stats

    func resetStats() {
        stats = [:]
        currentStreak = 0
        longestStreak = 0
        UserDefaults.standard.removeObject(forKey: Self.statsKey)
        UserDefaults.standard.removeObject(forKey: Self.streakKey)
    }

    func statsFor(_ id: String) -> QuestionStats {
        stats[id] ?? QuestionStats()
    }

    // MARK: - Private helpers

    private func weight(for question: Question) -> Double {
        let entry = stats[question.id] ?? QuestionStats()
        return max(1.0, Double(entry.attempts - entry.correct) + 1.0)
    }

    private func persistStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: Self.statsKey)
        }
    }

    private func persistStreak() {
        let data = StreakData(currentStreak: currentStreak, longestStreak: longestStreak)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.streakKey)
        }
    }
}

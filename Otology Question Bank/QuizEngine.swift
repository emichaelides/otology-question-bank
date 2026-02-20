import Foundation

@MainActor
final class QuizEngine: ObservableObject {
    @Published private(set) var currentQuestion: Question
    @Published private(set) var sessionEntries: [SessionEntry] = []
    @Published private(set) var isSessionComplete = false

    let questions: [Question]
    let sessionLength = 10
    @Published private(set) var stats: [String: QuestionStats]

    private static let statsKey = "questionStats"

    init() {
        let loaded = Question.loadAll()
        // Fallback placeholder so we always have at least one question
        questions = loaded.isEmpty ? [
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

        // Load persisted stats
        if let data = UserDefaults.standard.data(forKey: Self.statsKey),
           let decoded = try? JSONDecoder().decode([String: QuestionStats].self, from: data) {
            stats = decoded
        } else {
            stats = [:]
        }

        currentQuestion = questions[0]
        nextQuestion()
    }

    func answer(index: Int) {
        var entry = stats[currentQuestion.id] ?? QuestionStats()
        entry.attempts += 1
        if index == currentQuestion.correctIndex {
            entry.correct += 1
        }
        stats[currentQuestion.id] = entry
        persistStats()
        sessionEntries.append(SessionEntry(question: currentQuestion, selectedIndex: index))
        if sessionEntries.count >= sessionLength {
            isSessionComplete = true
        }
    }

    func startNewSession() {
        sessionEntries = []
        isSessionComplete = false
        nextQuestion()
    }

    func nextQuestion() {
        let weights = questions.map { weight(for: $0) }
        let total = weights.reduce(0, +)
        var threshold = Double.random(in: 0..<total)
        for (question, w) in zip(questions, weights) {
            threshold -= w
            if threshold < 0 {
                currentQuestion = question
                return
            }
        }
        currentQuestion = questions.last!
    }

    private func weight(for question: Question) -> Double {
        let entry = stats[question.id] ?? QuestionStats()
        return max(1.0, Double(entry.attempts - entry.correct) + 1.0)
    }

    func resetStats() {
        stats = [:]
        UserDefaults.standard.removeObject(forKey: Self.statsKey)
    }

    func statsFor(_ id: String) -> QuestionStats {
        stats[id] ?? QuestionStats()
    }

    private func persistStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: Self.statsKey)
        }
    }
}

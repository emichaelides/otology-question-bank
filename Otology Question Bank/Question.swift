import Foundation

struct Question: Codable, Identifiable {
    let id: String
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String

    static func loadAll() -> [Question] {
        Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil)?
            .flatMap { url in
                (try? JSONDecoder().decode([Question].self, from: Data(contentsOf: url))) ?? []
            }
        ?? []
    }
}

struct QuestionStats: Codable {
    var attempts: Int = 0
    var correct: Int = 0
}

struct SessionEntry {
    let question: Question
    let selectedIndex: Int
    let timeSpentSeconds: Int
    var wasCorrect: Bool { selectedIndex == question.correctIndex }
}

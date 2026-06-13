import Foundation

struct ProjectIdea: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let category: IdeaCategory
    let difficulty: DifficultyLevel
    let features: [String]
    let extensionIdea: String
    let isAIGenerated: Bool

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        category: IdeaCategory,
        difficulty: DifficultyLevel,
        features: [String],
        extensionIdea: String,
        isAIGenerated: Bool = false
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.difficulty = difficulty
        self.features = features
        self.extensionIdea = extensionIdea
        self.isAIGenerated = isAIGenerated
    }
}

extension ProjectIdea {
    static let preview = ProjectIdea(
        title: "StudySprint",
        summary: "Eine App fuer kurze fokussierte Lerneinheiten mit sichtbarem Fortschritt.",
        category: .mobileApp,
        difficulty: .beginner,
        features: [
            "Lern-Timer",
            "Aufgabenliste",
            "Fortschrittsuebersicht"
        ],
        extensionIdea: "Synchronisation ueber mehrere Geraete"
    )
}

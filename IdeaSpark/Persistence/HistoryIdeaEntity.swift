import Foundation
import SwiftData

@Model
final class HistoryIdeaEntity {
    var ideaID: UUID
    var title: String
    var summary: String
    var categoryRawValue: String
    var difficultyRawValue: String
    var featuresData: Data
    var extensionIdea: String
    var isAIGenerated: Bool
    var displayedAt: Date

    init(idea: ProjectIdea, displayedAt: Date = Date()) {
        self.ideaID = idea.id
        self.title = idea.title
        self.summary = idea.summary
        self.categoryRawValue = idea.category.rawValue
        self.difficultyRawValue = idea.difficulty.rawValue
        self.featuresData = (try? JSONEncoder().encode(idea.features)) ?? Data()
        self.extensionIdea = idea.extensionIdea
        self.isAIGenerated = idea.isAIGenerated
        self.displayedAt = displayedAt
    }

    func projectIdea() -> ProjectIdea {
        ProjectIdea(
            id: ideaID,
            title: title,
            summary: summary,
            category: IdeaCategory(rawValue: categoryRawValue) ?? .tool,
            difficulty: DifficultyLevel(rawValue: difficultyRawValue) ?? .beginner,
            features: (try? JSONDecoder().decode([String].self, from: featuresData)) ?? [],
            extensionIdea: extensionIdea,
            isAIGenerated: isAIGenerated
        )
    }
}

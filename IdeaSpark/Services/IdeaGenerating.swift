import Foundation

protocol IdeaGenerating {
    func generateIdea(
        category: IdeaCategory?,
        difficulty: DifficultyLevel?
    ) async throws -> ProjectIdea
}

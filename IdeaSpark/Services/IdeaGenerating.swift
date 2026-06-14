import Foundation

protocol IdeaGenerating {
    func generateIdea(
        category: IdeaCategory?,
        difficulty: DifficultyLevel?,
        prompt: String?
    ) async throws -> ProjectIdea
}

extension IdeaGenerating {
    func generateIdea(
        category: IdeaCategory?,
        difficulty: DifficultyLevel?
    ) async throws -> ProjectIdea {
        try await generateIdea(category: category, difficulty: difficulty, prompt: nil)
    }
}

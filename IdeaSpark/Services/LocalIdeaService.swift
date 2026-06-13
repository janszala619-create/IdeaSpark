import Foundation

actor LocalIdeaService: IdeaGenerating {
    private let bundle: Bundle
    private let resourceName: String
    private let bundledIdeas: [ProjectIdea]?
    private var cachedIdeas: [ProjectIdea]?
    private var previousIdeaID: UUID?

    init(
        bundle: Bundle = .main,
        resourceName: String = "ideas",
        ideas: [ProjectIdea]? = nil
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.bundledIdeas = ideas
    }

    func generateIdea(
        category: IdeaCategory?,
        difficulty: DifficultyLevel?
    ) async throws -> ProjectIdea {
        let ideas = try loadIdeas()
        let filteredIdeas = ideas.filter { idea in
            let categoryMatches = category.map { $0 == idea.category } ?? true
            let difficultyMatches = difficulty.map { $0 == idea.difficulty } ?? true
            return categoryMatches && difficultyMatches
        }

        guard !filteredIdeas.isEmpty else {
            throw IdeaGenerationError.noIdeasAvailable
        }

        let nonRepeatingIdeas = filteredIdeas.filter { $0.id != previousIdeaID }
        let selectionPool = nonRepeatingIdeas.isEmpty ? filteredIdeas : nonRepeatingIdeas

        guard let idea = selectionPool.randomElement() else {
            throw IdeaGenerationError.noIdeasAvailable
        }

        previousIdeaID = idea.id
        return idea
    }

    func ideas() throws -> [ProjectIdea] {
        try loadIdeas()
    }

    private func loadIdeas() throws -> [ProjectIdea] {
        if let cachedIdeas {
            return cachedIdeas
        }

        if let bundledIdeas {
            cachedIdeas = bundledIdeas
            return bundledIdeas
        }

        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw IdeaGenerationError.noIdeasAvailable
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedIdeas = try Self.decodeIdeas(from: data)
            cachedIdeas = decodedIdeas
            return decodedIdeas
        } catch let error as IdeaGenerationError {
            throw error
        } catch {
            #if DEBUG
            print("Local ideas failed to load: \(error)")
            #endif
            throw IdeaGenerationError.decodingFailed
        }
    }

    static func decodeIdeas(from data: Data) throws -> [ProjectIdea] {
        do {
            let ideas = try JSONDecoder().decode([ProjectIdea].self, from: data)
            guard !ideas.isEmpty else {
                throw IdeaGenerationError.noIdeasAvailable
            }
            return ideas
        } catch let error as IdeaGenerationError {
            throw error
        } catch {
            #if DEBUG
            print("Local ideas decoding failed: \(error)")
            #endif
            throw IdeaGenerationError.decodingFailed
        }
    }
}

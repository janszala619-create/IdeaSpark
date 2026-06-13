import Foundation
import Observation

enum IdeaSource: String, CaseIterable, Identifiable {
    case local
    case ai

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local:
            return "Lokal"
        case .ai:
            return "AI"
        }
    }
}

@MainActor
@Observable
final class DiscoverViewModel {
    var state: LoadingState<ProjectIdea> = .idle
    var notice: String?

    @ObservationIgnored private let localService: any IdeaGenerating
    @ObservationIgnored private let apiServiceFactory: (URL) -> any IdeaGenerating

    init(
        localService: any IdeaGenerating = LocalIdeaService(),
        apiServiceFactory: @escaping (URL) -> any IdeaGenerating = { APIIdeaService(baseURL: $0) }
    ) {
        self.localService = localService
        self.apiServiceFactory = apiServiceFactory
    }

    var currentIdea: ProjectIdea? {
        state.value
    }

    var isLoading: Bool {
        state.isLoading
    }

    func generateIdea(
        category: IdeaCategory?,
        difficulty: DifficultyLevel?,
        source: IdeaSource,
        aiGenerationEnabled: Bool,
        backendURLString: String
    ) async {
        state = .loading
        notice = nil

        if source == .ai, aiGenerationEnabled {
            do {
                guard let backendURL = AppConfiguration.backendURL(from: backendURLString) else {
                    throw IdeaGenerationError.invalidBackendURL
                }
                let idea = try await apiServiceFactory(backendURL)
                    .generateIdea(category: category, difficulty: difficulty)
                state = .loaded(idea)
                return
            } catch {
                notice = "AI nicht erreichbar. Es wurde automatisch eine lokale Idee geladen."
                #if DEBUG
                print("AI generation failed, falling back to local ideas: \(error)")
                #endif
            }
        } else if source == .ai {
            notice = "AI ist in den Einstellungen deaktiviert. Es wurde eine lokale Idee geladen."
        }

        do {
            let idea = try await localService.generateIdea(
                category: category,
                difficulty: difficulty
            )
            state = .loaded(idea)
        } catch {
            state = .failed(error)
        }
    }
}

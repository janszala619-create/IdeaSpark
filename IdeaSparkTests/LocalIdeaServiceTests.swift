import Foundation
import XCTest
@testable import IdeaSpark

final class LocalIdeaServiceTests: XCTestCase {
    func testRandomLocalIdeaSelectionReturnsAnIdea() async throws {
        let service = LocalIdeaService(ideas: Self.sampleIdeas)

        let idea = try await service.generateIdea(category: nil, difficulty: nil)

        XCTAssertTrue(Self.sampleIdeas.contains(idea))
        XCTAssertFalse(idea.isAIGenerated)
    }

    func testCategoryFilterLimitsSelection() async throws {
        let service = LocalIdeaService(ideas: Self.sampleIdeas)

        let idea = try await service.generateIdea(category: .webApp, difficulty: nil)

        XCTAssertEqual(idea.category, .webApp)
    }

    func testDifficultyFilterLimitsSelection() async throws {
        let service = LocalIdeaService(ideas: Self.sampleIdeas)

        let idea = try await service.generateIdea(category: nil, difficulty: .advanced)

        XCTAssertEqual(idea.difficulty, .advanced)
    }

    func testCombinedCategoryAndDifficultyFilterLimitsSelection() async throws {
        let service = LocalIdeaService(ideas: Self.sampleIdeas)

        let idea = try await service.generateIdea(category: .mobileApp, difficulty: .intermediate)

        XCTAssertEqual(idea.category, .mobileApp)
        XCTAssertEqual(idea.difficulty, .intermediate)
    }

    func testNoIdeasAvailableForUnmatchedFilters() async {
        let service = LocalIdeaService(ideas: Self.sampleIdeas)

        do {
            _ = try await service.generateIdea(category: .game, difficulty: .advanced)
            XCTFail("Expected noIdeasAvailable")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .noIdeasAvailable)
        }
    }

    func testAvoidsImmediateRepeatWhenAlternativesExist() async throws {
        let ideas = [
            Self.idea(id: UUID(uuidString: "22222222-2222-4222-8222-222222222221")!, title: "One"),
            Self.idea(id: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!, title: "Two")
        ]
        let service = LocalIdeaService(ideas: ideas)

        let first = try await service.generateIdea(category: .tool, difficulty: .beginner)
        let second = try await service.generateIdea(category: .tool, difficulty: .beginner)

        XCTAssertNotEqual(first.id, second.id)
    }

    func testDecodesBundledIdeasJSON() throws {
        let bundle = Bundle.main
        let url = try XCTUnwrap(bundle.url(forResource: "ideas", withExtension: "json"))
        let data = try Data(contentsOf: url)

        let ideas = try LocalIdeaService.decodeIdeas(from: data)

        XCTAssertGreaterThanOrEqual(ideas.count, 20)
        XCTAssertTrue(IdeaCategory.allCases.allSatisfy { category in
            ideas.contains { $0.category == category }
        })
        XCTAssertTrue(DifficultyLevel.allCases.allSatisfy { difficulty in
            ideas.contains { $0.difficulty == difficulty }
        })
    }

    func testEmptyLocalIdeasJSONThrowsNoIdeasAvailable() {
        do {
            _ = try LocalIdeaService.decodeIdeas(from: Data("[]".utf8))
            XCTFail("Expected noIdeasAvailable")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .noIdeasAvailable)
        }
    }

    func testInvalidLocalIdeasJSONThrowsDecodingFailed() {
        do {
            _ = try LocalIdeaService.decodeIdeas(from: Data("{not-json".utf8))
            XCTFail("Expected decodingFailed")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .decodingFailed)
        }
    }

    private static let sampleIdeas = [
        idea(
            id: UUID(uuidString: "22222222-2222-4222-8222-222222222223")!,
            title: "Web Start",
            category: .webApp,
            difficulty: .beginner
        ),
        idea(
            id: UUID(uuidString: "22222222-2222-4222-8222-222222222224")!,
            title: "Mobile Mid",
            category: .mobileApp,
            difficulty: .intermediate
        ),
        idea(
            id: UUID(uuidString: "22222222-2222-4222-8222-222222222225")!,
            title: "Tool Deep",
            category: .tool,
            difficulty: .advanced
        )
    ]

    private static func idea(
        id: UUID,
        title: String,
        category: IdeaCategory = .tool,
        difficulty: DifficultyLevel = .beginner
    ) -> ProjectIdea {
        ProjectIdea(
            id: id,
            title: title,
            summary: "Summary",
            category: category,
            difficulty: difficulty,
            features: ["One", "Two", "Three"],
            extensionIdea: "Extension"
        )
    }
}

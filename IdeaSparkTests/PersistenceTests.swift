import Foundation
import SwiftData
import XCTest
@testable import IdeaSpark

final class PersistenceTests: XCTestCase {
    @MainActor
    func testDuplicateFavoritesArePrevented() throws {
        let context = try makeContext()
        let idea = Self.idea(id: UUID(uuidString: "44444444-4444-4444-8444-444444444441")!)

        let firstInsert = try FavoriteStore.add(idea, in: context)
        let secondInsert = try FavoriteStore.add(idea, in: context)

        let favorites = try context.fetch(FetchDescriptor<FavoriteIdeaEntity>())
        XCTAssertTrue(firstInsert)
        XCTAssertFalse(secondInsert)
        XCTAssertEqual(favorites.count, 1)
    }

    @MainActor
    func testFavoriteToggleAddsThenRemovesIdea() throws {
        let context = try makeContext()
        let idea = Self.idea(id: UUID(uuidString: "44444444-4444-4444-8444-444444444442")!)

        let added = try FavoriteStore.toggle(idea, in: context)
        let removed = try FavoriteStore.toggle(idea, in: context)

        let favorites = try context.fetch(FetchDescriptor<FavoriteIdeaEntity>())
        XCTAssertTrue(added)
        XCTAssertFalse(removed)
        XCTAssertTrue(favorites.isEmpty)
    }

    @MainActor
    func testRemoveAllClearsFavorites() throws {
        let context = try makeContext()
        try FavoriteStore.add(Self.idea(title: "One"), in: context)
        try FavoriteStore.add(Self.idea(title: "Two"), in: context)

        try FavoriteStore.removeAll(in: context)

        let favorites = try context.fetch(FetchDescriptor<FavoriteIdeaEntity>())
        XCTAssertTrue(favorites.isEmpty)
    }

    @MainActor
    func testHistoryIsCappedAtFiftyIdeas() throws {
        let context = try makeContext()

        for index in 0..<55 {
            try HistoryStore.record(Self.idea(title: "Idea \(index)"), in: context)
        }

        let history = try context.fetch(FetchDescriptor<HistoryIdeaEntity>())
        XCTAssertEqual(history.count, HistoryStore.defaultLimit)
    }

    @MainActor
    func testHistoryReRecordingSameIdeaKeepsSingleEntry() throws {
        let context = try makeContext()
        let idea = Self.idea(id: UUID(uuidString: "44444444-4444-4444-8444-444444444443")!)

        try HistoryStore.record(idea, in: context)
        try HistoryStore.record(idea, in: context)

        let history = try context.fetch(FetchDescriptor<HistoryIdeaEntity>())
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.ideaID, idea.id)
    }

    @MainActor
    func testHistoryLimitZeroClearsRecordedIdea() throws {
        let context = try makeContext()

        try HistoryStore.record(Self.idea(), in: context, limit: 0)

        let history = try context.fetch(FetchDescriptor<HistoryIdeaEntity>())
        XCTAssertTrue(history.isEmpty)
    }

    @MainActor
    func testRemoveAllClearsHistory() throws {
        let context = try makeContext()
        try HistoryStore.record(Self.idea(title: "One"), in: context)
        try HistoryStore.record(Self.idea(title: "Two"), in: context)

        try HistoryStore.removeAll(in: context)

        let history = try context.fetch(FetchDescriptor<HistoryIdeaEntity>())
        XCTAssertTrue(history.isEmpty)
    }

    func testFavoriteEntityRoundTripPreservesIdeaFields() {
        let idea = ProjectIdea(
            id: UUID(uuidString: "44444444-4444-4444-8444-444444444444")!,
            title: "AI Archive",
            summary: "Summary",
            category: .artificialIntelligence,
            difficulty: .advanced,
            features: ["One", "Two", "Three"],
            extensionIdea: "Extension",
            isAIGenerated: true
        )

        let restoredIdea = FavoriteIdeaEntity(idea: idea).projectIdea()

        XCTAssertEqual(restoredIdea, idea)
    }

    @MainActor
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FavoriteIdeaEntity.self,
            HistoryIdeaEntity.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    private static func idea(
        id: UUID = UUID(),
        title: String = "Stored Idea"
    ) -> ProjectIdea {
        ProjectIdea(
            id: id,
            title: title,
            summary: "Summary",
            category: .tool,
            difficulty: .beginner,
            features: ["One", "Two", "Three"],
            extensionIdea: "Extension"
        )
    }
}

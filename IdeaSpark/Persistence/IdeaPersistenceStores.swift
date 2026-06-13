import Foundation
import SwiftData

@MainActor
enum FavoriteStore {
    static func add(_ idea: ProjectIdea, in context: ModelContext) throws -> Bool {
        if try contains(ideaID: idea.id, in: context) {
            return false
        }

        context.insert(FavoriteIdeaEntity(idea: idea))
        try context.save()
        return true
    }

    static func remove(_ idea: ProjectIdea, in context: ModelContext) throws -> Bool {
        guard let favorite = try favorite(ideaID: idea.id, in: context) else {
            return false
        }

        context.delete(favorite)
        try context.save()
        return true
    }

    static func toggle(_ idea: ProjectIdea, in context: ModelContext) throws -> Bool {
        if try contains(ideaID: idea.id, in: context) {
            _ = try remove(idea, in: context)
            return false
        }

        _ = try add(idea, in: context)
        return true
    }

    static func contains(ideaID: UUID, in context: ModelContext) throws -> Bool {
        try favorite(ideaID: ideaID, in: context) != nil
    }

    static func removeAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<FavoriteIdeaEntity>()
        let favorites = try context.fetch(descriptor)
        favorites.forEach { context.delete($0) }
        try context.save()
    }

    private static func favorite(ideaID: UUID, in context: ModelContext) throws -> FavoriteIdeaEntity? {
        var descriptor = FetchDescriptor<FavoriteIdeaEntity>(
            predicate: #Predicate { favorite in
                favorite.ideaID == ideaID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

@MainActor
enum HistoryStore {
    static let defaultLimit = 50

    static func record(
        _ idea: ProjectIdea,
        in context: ModelContext,
        limit: Int = defaultLimit
    ) throws {
        let ideaID = idea.id
        var existingDescriptor = FetchDescriptor<HistoryIdeaEntity>(
            predicate: #Predicate { history in
                history.ideaID == ideaID
            }
        )
        existingDescriptor.fetchLimit = 1

        if let existing = try context.fetch(existingDescriptor).first {
            context.delete(existing)
        }

        context.insert(HistoryIdeaEntity(idea: idea))
        try trim(in: context, limit: limit)
        try context.save()
    }

    static func removeAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<HistoryIdeaEntity>()
        let items = try context.fetch(descriptor)
        items.forEach { context.delete($0) }
        try context.save()
    }

    private static func trim(in context: ModelContext, limit: Int) throws {
        guard limit > 0 else {
            try removeAll(in: context)
            return
        }

        var descriptor = FetchDescriptor<HistoryIdeaEntity>(
            sortBy: [SortDescriptor(\.displayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = max(limit + 25, limit)

        let items = try context.fetch(descriptor)
        for item in items.dropFirst(limit) {
            context.delete(item)
        }
    }
}

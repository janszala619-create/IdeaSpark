import SwiftData
import SwiftUI

@MainActor
struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Query(sort: \.createdAt, order: .reverse) private var favorites: [FavoriteIdeaEntity]

    var body: some View {
        Group {
            if favorites.isEmpty {
                EmptyStateView(
                    title: "Noch keine Favoriten",
                    systemImage: "heart",
                    description: "Speichere spannende Ideen, um sie hier schnell wiederzufinden."
                )
            } else {
                List {
                    ForEach(favorites) { favorite in
                        let idea = favorite.projectIdea()
                        NavigationLink {
                            IdeaDetailView(
                                idea: idea,
                                isFavorite: true,
                                onToggleFavorite: { remove(idea) }
                            )
                        } label: {
                            IdeaRowView(idea: idea)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func delete(_ offsets: IndexSet) {
        do {
            let selectedFavorites = offsets.map { favorites[$0] }
            for favorite in selectedFavorites {
                modelContext.delete(favorite)
            }
            try modelContext.save()
            HapticManager.shared.fire(.favoriteChanged, isEnabled: hapticsEnabled)
        } catch {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }

    private func remove(_ idea: ProjectIdea) {
        do {
            _ = try FavoriteStore.remove(idea, in: modelContext)
            HapticManager.shared.fire(.favoriteChanged, isEnabled: hapticsEnabled)
        } catch {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }

}

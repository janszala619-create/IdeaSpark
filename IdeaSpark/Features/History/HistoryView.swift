import SwiftData
import SwiftUI

@MainActor
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Query(sort: \HistoryIdeaEntity.displayedAt, order: .reverse) private var history: [HistoryIdeaEntity]
    @Query private var favorites: [FavoriteIdeaEntity]

    var body: some View {
        Group {
            if history.isEmpty {
                EmptyStateView(
                    title: "Noch kein Verlauf",
                    systemImage: "clock",
                    description: "Generierte Ideen erscheinen hier automatisch."
                )
            } else {
                List {
                    ForEach(history.prefix(HistoryStore.defaultLimit)) { item in
                        let idea = item.projectIdea()
                        NavigationLink {
                            IdeaDetailView(
                                idea: idea,
                                isFavorite: isFavorite(idea),
                                onToggleFavorite: { toggleFavorite(idea) }
                            )
                        } label: {
                            IdeaRowView(
                                idea: idea,
                                subtitle: item.displayedAt.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            if !history.isEmpty {
                Button(role: .destructive) {
                    clearHistory()
                } label: {
                    Label("Verlauf loeschen", systemImage: "trash")
                }
                .accessibilityLabel("Verlauf loeschen")
            }
        }
    }

    private func isFavorite(_ idea: ProjectIdea) -> Bool {
        favorites.contains { $0.ideaID == idea.id }
    }

    private func toggleFavorite(_ idea: ProjectIdea) {
        do {
            _ = try FavoriteStore.toggle(idea, in: modelContext)
            HapticManager.shared.fire(.favoriteChanged, isEnabled: hapticsEnabled)
        } catch {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }

    private func clearHistory() {
        do {
            try HistoryStore.removeAll(in: modelContext)
            HapticManager.shared.fire(.favoriteChanged, isEnabled: hapticsEnabled)
        } catch {
            HapticManager.shared.fire(.error, isEnabled: hapticsEnabled)
        }
    }
}

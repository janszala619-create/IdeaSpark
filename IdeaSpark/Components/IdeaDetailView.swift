import SwiftUI

struct IdeaDetailView: View {
    let idea: ProjectIdea
    var isFavorite: Bool
    var onToggleFavorite: (() -> Void)?

    var body: some View {
        ScrollView {
            IdeaCardView(
                idea: idea,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(idea.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

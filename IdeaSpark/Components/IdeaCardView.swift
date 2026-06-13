import SwiftUI

struct IdeaCardView: View {
    let idea: ProjectIdea
    var isFavorite: Bool
    var showsFavoriteButton = true
    var onToggleFavorite: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Text(idea.summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Kernfeatures")
                    .font(.subheadline.weight(.semibold))
                ForEach(idea.features.prefix(3), id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .accessibilityLabel(feature)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Erweiterung")
                    .font(.subheadline.weight(.semibold))
                Label(idea.extensionIdea, systemImage: "arrow.up.forward.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("idea.card")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(idea.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Label(idea.category.displayName, systemImage: idea.category.symbolName)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.thinMaterial, in: Capsule())

                        DifficultyBadge(difficulty: idea.difficulty)
                    }
                }

                Spacer(minLength: 12)

                if showsFavoriteButton {
                    Button {
                        onToggleFavorite?()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(isFavorite ? .pink : .secondary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite ? "Aus Favoriten entfernen" : "Als Favorit speichern")
                    .accessibilityIdentifier("idea.favoriteButton")
                }
            }

            Label(idea.isAIGenerated ? "AI-generiert" : "Lokale Idee", systemImage: idea.isAIGenerated ? "sparkles" : "shippingbox")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Idea Card Light") {
    IdeaCardView(
        idea: .preview,
        isFavorite: false
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.light)
}

#Preview("Idea Card Dark Dynamic Type") {
    IdeaCardView(
        idea: .preview,
        isFavorite: true
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}

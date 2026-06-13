import SwiftUI

struct IdeaRowView: View {
    let idea: ProjectIdea
    var subtitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: idea.category.symbolName)
                .font(.title3)
                .foregroundStyle(.indigo)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(idea.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(idea.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(idea.category.displayName)
                    Text(idea.difficulty.displayName)
                    if idea.isAIGenerated {
                        Text("AI")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("idea.row")
    }
}

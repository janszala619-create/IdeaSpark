import SwiftUI

struct CategoryPicker: View {
    @Binding var selection: IdeaCategory?

    var body: some View {
        Picker("Kategorie", selection: $selection) {
            Label("Alle Kategorien", systemImage: "square.grid.2x2")
                .tag(Optional<IdeaCategory>.none)
            ForEach(IdeaCategory.allCases) { category in
                Label(category.displayName, systemImage: category.symbolName)
                    .tag(Optional(category))
            }
        }
        .accessibilityLabel("Kategorie filtern")
        .accessibilityIdentifier("filters.category")
    }
}

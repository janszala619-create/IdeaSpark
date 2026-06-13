import SwiftUI

@MainActor
enum AppTab: String, CaseIterable, Identifiable {
    case discover
    case favorites
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discover:
            return "Entdecken"
        case .favorites:
            return "Favoriten"
        case .history:
            return "Verlauf"
        case .settings:
            return "Einstellungen"
        }
    }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .discover:
            DiscoverView()
        case .favorites:
            FavoritesView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    var label: some View {
        switch self {
        case .discover:
            Label(title, systemImage: "sparkles")
        case .favorites:
            Label(title, systemImage: "heart")
        case .history:
            Label(title, systemImage: "clock.arrow.circlepath")
        case .settings:
            Label(title, systemImage: "gearshape")
        }
    }
}

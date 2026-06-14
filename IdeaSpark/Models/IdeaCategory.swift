import Foundation

enum IdeaCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case webApp
    case mobileApp
    case artificialIntelligence
    case game
    case tool
    case automation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .webApp:
            return "Web-App"
        case .mobileApp:
            return "Mobile-App"
        case .artificialIntelligence:
            return "AI"
        case .game:
            return "Game"
        case .tool:
            return "Tool"
        case .automation:
            return "Automation"
        }
    }

    var symbolName: String {
        switch self {
        case .webApp:
            return "globe"
        case .mobileApp:
            return "iphone"
        case .artificialIntelligence:
            return "brain.head.profile"
        case .game:
            return "gamecontroller"
        case .tool:
            return "wrench.and.screwdriver"
        case .automation:
            return "gearshape.2"
        }
    }
}

import Foundation

enum DifficultyLevel: String, Codable, CaseIterable, Hashable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner:
            return "Einsteiger"
        case .intermediate:
            return "Fortgeschritten"
        case .advanced:
            return "Anspruchsvoll"
        }
    }

    var symbolName: String {
        switch self {
        case .beginner:
            return "leaf"
        case .intermediate:
            return "bolt"
        case .advanced:
            return "flame"
        }
    }
}

import Foundation

enum IdeaGenerationError: LocalizedError, Equatable {
    case noIdeasAvailable
    case invalidResponse
    case invalidBackendURL
    case networkUnavailable
    case serverError(statusCode: Int)
    case decodingFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .noIdeasAvailable:
            return "Fuer diese Filter gibt es gerade keine passende Idee."
        case .invalidResponse:
            return "Die Antwort des Servers konnte nicht verarbeitet werden."
        case .invalidBackendURL:
            return "Die Backend-URL ist ungueltig oder verwendet kein HTTPS."
        case .networkUnavailable:
            return "Die Netzwerkverbindung ist gerade nicht verfuegbar."
        case let .serverError(statusCode):
            return "Der Server hat mit Fehler \(statusCode) geantwortet."
        case .decodingFailed:
            return "Die Ideendaten konnten nicht gelesen werden."
        case .timeout:
            return "Die Anfrage hat zu lange gedauert."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noIdeasAvailable:
            return "Passe Kategorie oder Schwierigkeit an und versuche es erneut."
        case .invalidBackendURL:
            return "Pruefe die Backend-URL in den Einstellungen."
        case .networkUnavailable, .timeout, .serverError:
            return "IdeaSpark kann stattdessen lokale Ideen verwenden."
        case .invalidResponse, .decodingFailed:
            return "Versuche es spaeter erneut oder nutze lokale Ideen."
        }
    }
}

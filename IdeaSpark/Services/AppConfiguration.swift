import Foundation

enum AppConfiguration {
    static let defaultBackendURLString = "https://localhost:3000"

    static var configuredBackendURLString: String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "IDEASPARK_API_BASE_URL") as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return defaultBackendURLString
        }
        return value
    }

    static func backendURL(from string: String) -> URL? {
        let trimmedValue = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: trimmedValue),
            url.scheme?.lowercased() == "https",
            url.host?.isEmpty == false,
            (url.user ?? "").isEmpty,
            url.password == nil,
            url.query == nil,
            url.fragment == nil
        else {
            return nil
        }
        return url
    }
}

import Foundation

struct APIIdeaService: IdeaGenerating {
    private struct GenerateIdeaRequest: Encodable {
        let category: String?
        let difficulty: String?
    }

    let baseURL: URL
    let session: URLSession
    let timeoutNanoseconds: UInt64

    init(
        baseURL: URL,
        session: URLSession = .shared,
        timeoutSeconds: TimeInterval = 10
    ) {
        self.baseURL = baseURL
        self.session = session
        self.timeoutNanoseconds = UInt64(max(timeoutSeconds, 0.05) * 1_000_000_000)
    }

    func generateIdea(
        category: IdeaCategory?,
        difficulty: DifficultyLevel?
    ) async throws -> ProjectIdea {
        guard baseURL.scheme?.lowercased() == "https" else {
            throw IdeaGenerationError.invalidBackendURL
        }

        let endpoint = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("generate-idea")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = TimeInterval(timeoutNanoseconds) / 1_000_000_000
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(
            GenerateIdeaRequest(
                category: category?.rawValue,
                difficulty: difficulty?.rawValue
            )
        )

        do {
            let (data, response) = try await perform(request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw IdeaGenerationError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200..<300:
                do {
                    return try JSONDecoder().decode(ProjectIdea.self, from: data)
                } catch {
                    #if DEBUG
                    print("API response decoding failed: \(error)")
                    #endif
                    throw IdeaGenerationError.decodingFailed
                }
            case 408:
                throw IdeaGenerationError.timeout
            case 500...599:
                throw IdeaGenerationError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw IdeaGenerationError.invalidResponse
            }
        } catch let error as IdeaGenerationError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                throw IdeaGenerationError.networkUnavailable
            case .timedOut:
                throw IdeaGenerationError.timeout
            default:
                #if DEBUG
                print("API request failed: \(error)")
                #endif
                throw IdeaGenerationError.invalidResponse
            }
        } catch {
            #if DEBUG
            print("API request failed: \(error)")
            #endif
            throw IdeaGenerationError.invalidResponse
        }
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await withThrowingTaskGroup(of: (Data, URLResponse).self) { group in
            group.addTask {
                try await session.data(for: request)
            }

            group.addTask {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                throw IdeaGenerationError.timeout
            }

            guard let result = try await group.next() else {
                throw IdeaGenerationError.invalidResponse
            }
            group.cancelAll()
            return result
        }
    }
}

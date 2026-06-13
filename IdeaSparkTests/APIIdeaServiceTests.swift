import Foundation
import XCTest
@testable import IdeaSpark

final class APIIdeaServiceTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.responseDelay = 0
        super.tearDown()
    }

    func testDecodesAPIResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/generate-idea")
            let body = try Self.requestBodyData(from: request)
            let payload = try JSONDecoder().decode(GenerateIdeaPayload.self, from: body)
            XCTAssertEqual(payload.category, IdeaCategory.mobileApp.rawValue)
            XCTAssertEqual(payload.difficulty, DifficultyLevel.beginner.rawValue)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.validResponseData)
        }
        let service = APIIdeaService(
            baseURL: URL(string: "https://api.example.com")!,
            session: Self.mockSession()
        )

        let idea = try await service.generateIdea(category: .mobileApp, difficulty: .beginner)

        XCTAssertEqual(idea.title, "StudySprint")
        XCTAssertEqual(idea.category, .mobileApp)
        XCTAssertTrue(idea.isAIGenerated)
    }

    func testDecodingFailureIsMapped() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("not-json".utf8))
        }
        let service = APIIdeaService(
            baseURL: URL(string: "https://api.example.com")!,
            session: Self.mockSession()
        )

        do {
            _ = try await service.generateIdea(category: nil, difficulty: nil)
            XCTFail("Expected decoding failure")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .decodingFailed)
        }
    }

    func testServerErrorIsMapped() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let service = APIIdeaService(
            baseURL: URL(string: "https://api.example.com")!,
            session: Self.mockSession()
        )

        do {
            _ = try await service.generateIdea(category: nil, difficulty: nil)
            XCTFail("Expected server error")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .serverError(statusCode: 500))
        }
    }

    func testRequestTimeoutStatusIsMapped() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 408,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let service = APIIdeaService(
            baseURL: URL(string: "https://api.example.com")!,
            session: Self.mockSession()
        )

        do {
            _ = try await service.generateIdea(category: nil, difficulty: nil)
            XCTFail("Expected timeout")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .timeout)
        }
    }

    func testClientErrorIsMappedToInvalidResponse() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let service = APIIdeaService(
            baseURL: URL(string: "https://api.example.com")!,
            session: Self.mockSession()
        )

        do {
            _ = try await service.generateIdea(category: nil, difficulty: nil)
            XCTFail("Expected invalidResponse")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .invalidResponse)
        }
    }

    func testNetworkErrorIsMapped() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        let service = APIIdeaService(
            baseURL: URL(string: "https://api.example.com")!,
            session: Self.mockSession()
        )

        do {
            _ = try await service.generateIdea(category: nil, difficulty: nil)
            XCTFail("Expected networkUnavailable")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .networkUnavailable)
        }
    }

    func testInvalidBackendURLIsRejected() async {
        let service = APIIdeaService(
            baseURL: URL(string: "http://api.example.com")!,
            session: Self.mockSession()
        )

        do {
            _ = try await service.generateIdea(category: nil, difficulty: nil)
            XCTFail("Expected invalidBackendURL")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .invalidBackendURL)
        }
    }

    func testAppConfigurationAcceptsOnlyHTTPSBackendURLs() {
        XCTAssertNotNil(AppConfiguration.backendURL(from: " https://api.example.com "))
        XCTAssertNil(AppConfiguration.backendURL(from: "http://api.example.com"))
        XCTAssertNil(AppConfiguration.backendURL(from: "not a url"))
        XCTAssertNil(AppConfiguration.backendURL(from: "https://token@api.example.com"))
        XCTAssertNil(AppConfiguration.backendURL(from: "https://user:secret@api.example.com"))
        XCTAssertNil(AppConfiguration.backendURL(from: "https://api.example.com?token=abc"))
        XCTAssertNil(AppConfiguration.backendURL(from: "https://api.example.com#token"))
    }

    func testTimeoutBehavior() async {
        MockURLProtocol.responseDelay = 1
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.validResponseData)
        }
        let service = APIIdeaService(
            baseURL: URL(string: "https://api.example.com")!,
            session: Self.mockSession(),
            timeoutSeconds: 0.05
        )

        do {
            _ = try await service.generateIdea(category: nil, difficulty: nil)
            XCTFail("Expected timeout")
        } catch {
            XCTAssertEqual(error as? IdeaGenerationError, .timeout)
        }
    }

    private static func mockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private static func requestBodyData(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let bodyStream = request.httpBodyStream else {
            return Data()
        }

        bodyStream.open()
        defer { bodyStream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)

        while bodyStream.hasBytesAvailable {
            let bytesRead = buffer.withUnsafeMutableBytes { rawBuffer in
                guard let baseAddress = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                    return 0
                }
                return bodyStream.read(baseAddress, maxLength: buffer.count)
            }
            if bytesRead < 0 {
                throw bodyStream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if bytesRead == 0 {
                break
            }
            data.append(buffer, count: bytesRead)
        }

        return data
    }

    private static let validResponseData = """
    {
      "id": "33333333-3333-4333-8333-333333333333",
      "title": "StudySprint",
      "summary": "Eine App fuer kurze fokussierte Lerneinheiten.",
      "category": "mobileApp",
      "difficulty": "beginner",
      "features": ["Lern-Timer", "Aufgabenliste", "Fortschrittsuebersicht"],
      "extensionIdea": "Synchronisation ueber mehrere Geraete",
      "isAIGenerated": true
    }
    """.data(using: .utf8)!
}

private struct GenerateIdeaPayload: Decodable {
    let category: String?
    let difficulty: String?
}

@MainActor
final class DiscoverViewModelTests: XCTestCase {
    func testAIGenerationFallsBackToLocalIdeaWhenServiceFails() async {
        let localIdea = Self.idea(title: "Local Fallback")
        let viewModel = DiscoverViewModel(
            localService: StubIdeaService(result: .success(localIdea)),
            apiServiceFactory: { _ in
                StubIdeaService(result: .failure(.networkUnavailable))
            }
        )

        await viewModel.generateIdea(
            category: .tool,
            difficulty: .beginner,
            source: .ai,
            aiGenerationEnabled: true,
            backendURLString: "https://api.example.com"
        )

        XCTAssertEqual(viewModel.currentIdea, localIdea)
        XCTAssertEqual(
            viewModel.notice,
            "AI nicht erreichbar. Es wurde automatisch eine lokale Idee geladen."
        )
    }

    func testDisabledAIGenerationUsesLocalIdea() async {
        let localIdea = Self.idea(title: "Local Only")
        let viewModel = DiscoverViewModel(
            localService: StubIdeaService(result: .success(localIdea)),
            apiServiceFactory: { _ in
                StubIdeaService(result: .failure(.serverError(statusCode: 500)))
            }
        )

        await viewModel.generateIdea(
            category: nil,
            difficulty: nil,
            source: .ai,
            aiGenerationEnabled: false,
            backendURLString: "https://api.example.com"
        )

        XCTAssertEqual(viewModel.currentIdea, localIdea)
        XCTAssertEqual(
            viewModel.notice,
            "AI ist in den Einstellungen deaktiviert. Es wurde eine lokale Idee geladen."
        )
    }

    private static func idea(title: String) -> ProjectIdea {
        ProjectIdea(
            id: UUID(uuidString: "55555555-5555-4555-8555-555555555555")!,
            title: title,
            summary: "Summary",
            category: .tool,
            difficulty: .beginner,
            features: ["One", "Two", "Three"],
            extensionIdea: "Extension"
        )
    }
}

private actor StubIdeaService: IdeaGenerating {
    private let result: Result<ProjectIdea, IdeaGenerationError>

    init(result: Result<ProjectIdea, IdeaGenerationError>) {
        self.result = result
    }

    func generateIdea(
        category: IdeaCategory?,
        difficulty: DifficultyLevel?
    ) async throws -> ProjectIdea {
        try result.get()
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var responseDelay: TimeInterval = 0

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: IdeaGenerationError.invalidResponse)
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            let finish = { [weak self] in
                guard let self else {
                    return
                }
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            }

            if Self.responseDelay > 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + Self.responseDelay, execute: finish)
            } else {
                finish()
            }
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

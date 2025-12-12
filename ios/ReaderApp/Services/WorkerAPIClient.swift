import Foundation

enum WorkerAPIClient {
    // Worker URL - uses the deployed Cloudflare Worker
    // For local development, change to http://localhost:8787
    private static let baseURL = URL(string: "https://reader-app-api.blah.workers.dev")!

    struct QueryRequest: Encodable {
        let image: String // base64
        let prompt: String
        let provider: String
        let model: String
        let searchEnabled: Bool
        let searchResultsPerQuery: Int
    }

    struct QueryResponse: Decodable {
        let response: String
        let provider: String
        let model: String
        let searchQueries: [String]?
        let searchPerformed: Bool?
    }

    struct TranscribeRequest: Encodable {
        let audio: String // base64
        let format: String
    }

    struct TranscribeResponse: Decodable {
        let text: String
    }

    struct ErrorResponse: Decodable {
        let error: String
    }

    static func query(
        image: Data,
        prompt: String,
        provider: ProviderType,
        model: ModelType,
        searchEnabled: Bool,
        searchResultsPerQuery: Int
    ) async throws -> QueryResponse {
        let url = baseURL.appendingPathComponent("api/query")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = QueryRequest(
            image: image.base64EncodedString(),
            prompt: prompt,
            provider: provider.rawValue,
            model: model.rawValue,
            searchEnabled: searchEnabled,
            searchResultsPerQuery: searchResultsPerQuery
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ProviderError.apiError(errorResponse.error)
            }
            throw ProviderError.apiError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(QueryResponse.self, from: data)
    }

    static func transcribe(audio: Data, format: String) async throws -> String {
        let url = baseURL.appendingPathComponent("api/transcribe")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TranscribeRequest(
            audio: audio.base64EncodedString(),
            format: format
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ProviderError.apiError(errorResponse.error)
            }
            throw ProviderError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(TranscribeResponse.self, from: data)
        return result.text
    }
}

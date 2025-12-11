import Foundation

struct GeminiProvider: VisionProvider {
    static let providerType: ProviderType = .gemini
    static let displayName = "Gemini"

    private static func endpoint(apiKey: String, model: ModelType) -> URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model.rawValue):generateContent?key=\(apiKey)")!
    }

    static func query(image: Data, prompt: String, apiKey: String, model: ModelType) async throws -> String {
        let base64Image = image.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: endpoint(apiKey: apiKey, model: model))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ProviderError.apiError(message)
            }
            throw ProviderError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw ProviderError.invalidResponse
        }
        
        return text
    }
}

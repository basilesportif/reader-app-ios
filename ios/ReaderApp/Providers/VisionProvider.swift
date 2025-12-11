import Foundation

enum ProviderType: String, CaseIterable, Identifiable {
    case claude
    case openai
    case gemini
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .openai: return "OpenAI"
        case .gemini: return "Gemini"
        }
    }
}

enum ProviderError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured"
        case .invalidResponse:
            return "Invalid response from API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

protocol VisionProvider {
    static var providerType: ProviderType { get }
    static var displayName: String { get }
    static func query(image: Data, prompt: String, apiKey: String) async throws -> String
}

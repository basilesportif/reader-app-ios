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

    var availableModels: [ModelType] {
        switch self {
        case .claude: return [.claudeSonnet, .claudeOpus]
        case .openai: return [.gpt5_1, .gpt5Mini]
        case .gemini: return [.gemini3Pro, .gemini25Flash]
        }
    }

    var defaultModel: ModelType {
        switch self {
        case .claude: return .claudeSonnet
        case .openai: return .gpt5_1
        case .gemini: return .gemini3Pro
        }
    }
}

enum ModelType: String, CaseIterable, Identifiable {
    // Claude models
    case claudeSonnet = "claude-sonnet-4-5-20250929"
    case claudeOpus = "claude-opus-4-5-20251101"

    // OpenAI models
    case gpt5_1 = "gpt-5.1"
    case gpt5Mini = "gpt-5-mini"

    // Gemini models
    case gemini3Pro = "gemini-3-pro-preview"
    case gemini25Flash = "gemini-2.5-flash"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeSonnet: return "Claude Sonnet 4.5"
        case .claudeOpus: return "Claude Opus 4.5"
        case .gpt5_1: return "GPT-5.1"
        case .gpt5Mini: return "GPT-5 Mini"
        case .gemini3Pro: return "Gemini 3 Pro Preview"
        case .gemini25Flash: return "Gemini 2.5 Flash"
        }
    }

    var provider: ProviderType {
        switch self {
        case .claudeSonnet, .claudeOpus: return .claude
        case .gpt5_1, .gpt5Mini: return .openai
        case .gemini3Pro, .gemini25Flash: return .gemini
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
    static func query(image: Data, prompt: String, apiKey: String, model: ModelType) async throws -> String
}

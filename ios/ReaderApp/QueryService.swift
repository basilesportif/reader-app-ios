import Foundation
import SwiftUI
import CoreGraphics
import ImageIO

@Observable
class QueryService {
    var currentProvider: ProviderType {
        didSet {
            UserDefaults.standard.set(currentProvider.rawValue, forKey: "selectedProvider")
            // Reset model to default for the new provider
            currentModel = currentProvider.defaultModel
        }
    }

    var currentModel: ModelType {
        didSet {
            UserDefaults.standard.set(currentModel.rawValue, forKey: "selectedModel")
        }
    }

    var isLoading = false
    var lastError: String?

    init() {
        // Load provider
        let provider: ProviderType
        if let savedProvider = UserDefaults.standard.string(forKey: "selectedProvider"),
           let saved = ProviderType(rawValue: savedProvider) {
            provider = saved
        } else {
            provider = .claude
        }

        // Load model (must be valid for the current provider)
        let model: ModelType
        if let savedModel = UserDefaults.standard.string(forKey: "selectedModel"),
           let saved = ModelType(rawValue: savedModel),
           saved.provider == provider {
            model = saved
        } else {
            model = provider.defaultModel
        }

        // Initialize both at once to satisfy @Observable requirements
        self.currentProvider = provider
        self.currentModel = model
    }

    func query(image: Data, prompt: String) async throws -> String {
        guard let apiKey = KeychainManager.getKey(for: currentProvider), !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        let processedImage = processImage(image)

        switch currentProvider {
        case .claude:
            return try await ClaudeProvider.query(image: processedImage, prompt: prompt, apiKey: apiKey, model: currentModel)
        case .openai:
            return try await OpenAIProvider.query(image: processedImage, prompt: prompt, apiKey: apiKey, model: currentModel)
        case .gemini:
            return try await GeminiProvider.query(image: processedImage, prompt: prompt, apiKey: apiKey, model: currentModel)
        }
    }
    
    private func processImage(_ imageData: Data) -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return imageData
        }
        
        let maxDimension: CGFloat = 2048
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        var newWidth = width
        var newHeight = height
        
        if width > maxDimension || height > maxDimension {
            if width > height {
                newWidth = maxDimension
                newHeight = height * (maxDimension / width)
            } else {
                newHeight = maxDimension
                newWidth = width * (maxDimension / height)
            }
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(newWidth),
            height: Int(newHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return imageData
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        guard let resizedImage = context.makeImage() else {
            return imageData
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return imageData
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]
        
        CGImageDestinationAddImage(destination, resizedImage, options as CFDictionary)
        CGImageDestinationFinalize(destination)
        
        return mutableData as Data
    }
}

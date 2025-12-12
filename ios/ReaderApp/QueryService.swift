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

    var searchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(searchEnabled, forKey: "searchEnabled")
        }
    }

    var searchResultsPerQuery: Int {
        didSet {
            UserDefaults.standard.set(searchResultsPerQuery, forKey: "searchResultsPerQuery")
        }
    }

    var isLoading = false
    var lastError: String?

    // Metadata from last query
    var lastSearchQueries: [String]?
    var lastSearchPerformed: Bool = false

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

        // Load search settings
        let searchEnabledValue: Bool
        if UserDefaults.standard.object(forKey: "searchEnabled") != nil {
            searchEnabledValue = UserDefaults.standard.bool(forKey: "searchEnabled")
        } else {
            searchEnabledValue = true // default: enabled
        }

        let searchResultsValue: Int
        let storedResults = UserDefaults.standard.integer(forKey: "searchResultsPerQuery")
        if storedResults > 0 {
            searchResultsValue = min(10, max(1, storedResults))
        } else {
            searchResultsValue = 5 // default: 5
        }

        // Initialize all at once to satisfy @Observable requirements
        self.currentProvider = provider
        self.currentModel = model
        self.searchEnabled = searchEnabledValue
        self.searchResultsPerQuery = searchResultsValue
    }

    func query(image: Data, prompt: String) async throws -> String {
        let processedImage = processImage(image)

        let result = try await WorkerAPIClient.query(
            image: processedImage,
            prompt: prompt,
            provider: currentProvider,
            model: currentModel,
            searchEnabled: searchEnabled,
            searchResultsPerQuery: searchResultsPerQuery
        )

        // Store search metadata
        lastSearchQueries = result.searchQueries
        lastSearchPerformed = result.searchPerformed ?? false

        return result.response
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

import Foundation
import SwiftUI
import CoreGraphics
import ImageIO

struct QueryHistoryItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let prompt: String
    let response: String
    let provider: String
    let model: String
    let thumbnail: Data?

    init(prompt: String, response: String, provider: String, model: String, thumbnail: Data?) {
        self.id = UUID()
        self.timestamp = Date()
        self.prompt = prompt
        self.response = response
        self.provider = provider
        self.model = model
        self.thumbnail = thumbnail
    }
}

@Observable
class HistoryManager {
    private static let storageKey = "reader-app-query-history"
    private static let maxHistoryItems = 50

    var history: [QueryHistoryItem] = []

    init() {
        loadHistory()
    }

    func addToHistory(prompt: String, response: String, provider: String, model: String, imageData: Data?) {
        let thumbnail = imageData.flatMap { createThumbnail(from: $0) }

        let item = QueryHistoryItem(
            prompt: prompt,
            response: response,
            provider: provider,
            model: model,
            thumbnail: thumbnail
        )

        history.insert(item, at: 0)

        // Keep only the most recent items
        if history.count > Self.maxHistoryItems {
            history = Array(history.prefix(Self.maxHistoryItems))
        }

        saveHistory()
    }

    func removeFromHistory(id: UUID) {
        history.removeAll { $0.id == id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }

        do {
            let decoder = JSONDecoder()
            history = try decoder.decode([QueryHistoryItem].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    private func createThumbnail(from imageData: Data, maxSize: CGFloat = 100) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let scale = min(maxSize / width, maxSize / height)
        let newWidth = width * scale
        let newHeight = height * scale

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
            return nil
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let resizedImage = context.makeImage() else {
            return nil
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.5
        ]

        CGImageDestinationAddImage(destination, resizedImage, options as CFDictionary)
        CGImageDestinationFinalize(destination)

        return mutableData as Data
    }
}

// Helper to format relative time
extension QueryHistoryItem {
    var relativeTimeString: String {
        let now = Date()
        let diff = now.timeIntervalSince(timestamp)

        if diff < 60 {
            return "Just now"
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            return "\(minutes)m ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: timestamp)
        }
    }
}

import Foundation
import AVFoundation

@Observable
class VoiceInputManager: NSObject {
    enum State {
        case idle
        case recording
        case transcribing
    }

    var state: State = .idle
    var error: String?

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    func startRecording() async {
        error = nil

        // Request microphone permission
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            self.error = "Failed to configure audio session"
            return
        }

        // Check permission
        if await AVAudioApplication.requestRecordPermission() == false {
            error = "Microphone access denied"
            return
        }

        // Create temp file URL
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("voice_\(UUID().uuidString).m4a")

        guard let url = recordingURL else { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            state = .recording
        } catch {
            self.error = "Failed to start recording"
        }
    }

    func stopRecording() async -> String? {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return nil
        }

        recorder.stop()
        state = .transcribing

        defer {
            // Clean up temp file
            if let url = recordingURL {
                try? FileManager.default.removeItem(at: url)
            }
            recordingURL = nil
            audioRecorder = nil
            state = .idle
        }

        guard let url = recordingURL,
              let audioData = try? Data(contentsOf: url) else {
            error = "Failed to read recording"
            return nil
        }

        // Call transcription API
        do {
            let text = try await transcribe(audioData: audioData)
            return text
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func cancelRecording() {
        audioRecorder?.stop()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        audioRecorder = nil
        state = .idle
        error = nil
    }

    private func transcribe(audioData: Data) async throws -> String {
        // Get OpenAI API key
        guard let apiKey = KeychainManager.getKey(for: .openai), !apiKey.isEmpty else {
            throw NSError(
                domain: "VoiceInput",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI API key required for voice input. Please add it in Settings."]
            )
        }

        // Call OpenAI Whisper API directly
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "VoiceInput",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            )
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(WhisperErrorResponse.self, from: data) {
                throw NSError(
                    domain: "VoiceInput",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message]
                )
            }
            throw NSError(
                domain: "VoiceInput",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Transcription failed with status \(httpResponse.statusCode)"]
            )
        }

        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return result.text
    }
}

private struct WhisperResponse: Codable {
    let text: String
}

private struct WhisperErrorResponse: Codable {
    let error: WhisperError
}

private struct WhisperError: Codable {
    let message: String
}

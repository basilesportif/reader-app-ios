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
        // Use worker API for transcription
        return try await WorkerAPIClient.transcribe(audio: audioData, format: "m4a")
    }
}

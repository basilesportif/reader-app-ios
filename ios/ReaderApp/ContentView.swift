import SwiftUI

struct ContentView: View {
    @State private var cameraManager = CameraManager()
    @State private var queryService = QueryService()
    @State private var historyManager = HistoryManager()
    @State private var voiceInputManager = VoiceInputManager()
    @State private var response = ""
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var errorMessage: String?
    @State private var lastQueryImageData: Data?
    @State private var queryTask: Task<Void, Never>?
    @State private var recordingStartTime: Date?
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0

    enum ViewState {
        case camera           // Live camera feed, ready to capture
        case recording        // Photo captured, voice recording in progress
        case transcribing     // Processing audio
        case retryAudio       // Transcription failed/empty, show photo + retry button
        case querying         // Sending to AI
        case response         // Showing AI response
    }

    @State private var viewState: ViewState = .camera

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                switch viewState {
                case .camera:
                    cameraView
                case .recording:
                    recordingView
                case .transcribing:
                    transcribingView
                case .retryAudio:
                    retryAudioView
                case .querying:
                    queryingView
                case .response:
                    responseView
                }
            }
            .navigationTitle("Reader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showHistory = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "clock.arrow.circlepath")
                                if !historyManager.history.isEmpty {
                                    Text("\(historyManager.history.count)")
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Picker("Provider", selection: $queryService.currentProvider) {
                            ForEach(ProviderType.allCases) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Model", selection: $queryService.currentModel) {
                            ForEach(queryService.currentProvider.availableModels) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(historyManager: historyManager) { item in
                    response = item.response
                    viewState = .response
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    // MARK: - Camera View
    private var cameraView: some View {
        ZStack {
            if cameraManager.isAuthorized {
                CameraPreview(cameraManager: cameraManager)
                    .ignoresSafeArea()

                // Floating action button in bottom-right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            startCombinedCapture()
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 40)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Camera access required")
                        .foregroundColor(.white)
                    Text("Please enable camera access in Settings")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Recording View
    private var recordingView: some View {
        ZStack {
            // Frozen captured photo as background
            if let imageData = cameraManager.capturedImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Dark overlay
            Color.black.opacity(0.3)

            VStack {
                Spacer()

                // Recording indicator
                VStack(spacing: 16) {
                    // Pulsing red dot
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .modifier(PulsingAnimation())

                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    // Duration timer
                    Text(formatDuration(recordingDuration))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(.white)

                    Text("Tap to finish and send")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
                .background(.ultraThinMaterial.opacity(0.8))
                .cornerRadius(16)

                Spacer()

                // Stop/Send button
                Button {
                    stopAndProcess()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 70, height: 70)

                        Image(systemName: "stop.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)

                // Cancel button
                Button("Cancel") {
                    cancelRecording()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Transcribing View
    private var transcribingView: some View {
        ZStack {
            // Frozen captured photo as background
            if let imageData = cameraManager.capturedImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Dark overlay
            Color.black.opacity(0.5)

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Transcribing audio...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(16)
        }
    }

    // MARK: - Retry Audio View
    private var retryAudioView: some View {
        ZStack {
            // Frozen captured photo as background
            if let imageData = cameraManager.capturedImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Dark overlay
            Color.black.opacity(0.5)

            VStack(spacing: 24) {
                // Error message
                VStack(spacing: 8) {
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text("No speech detected")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Tap the microphone to try again")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Retry microphone button
                Button {
                    retryRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black)
                    }
                }

                // Cancel button
                Button("Cancel") {
                    resetToCamera()
                }
                .font(.headline)
                .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(16)
        }
    }

    // MARK: - Querying View
    private var queryingView: some View {
        ZStack {
            // Frozen captured photo as background
            if let imageData = cameraManager.capturedImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Dark overlay
            Color.black.opacity(0.5)

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Querying \(queryService.currentModel.displayName)...")
                    .font(.headline)
                    .foregroundColor(.white)

                Button("Cancel") {
                    cancelQuery()
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 8)
            }
            .padding(32)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(16)
        }
    }

    // MARK: - Response View
    private var responseView: some View {
        VStack {
            ScrollView {
                Text(response)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 20) {
                Button("New Capture") {
                    resetToCamera()
                }
                .buttonStyle(.bordered)

                Button {
                    UIPasteboard.general.string = response
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func startCombinedCapture() {
        Task {
            // First capture the photo
            if let _ = await cameraManager.capturePhoto() {
                // Then start voice recording
                await voiceInputManager.startRecording()

                // Start the timer
                recordingStartTime = Date()
                recordingDuration = 0
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    if let startTime = recordingStartTime {
                        recordingDuration = Date().timeIntervalSince(startTime)
                    }
                }

                viewState = .recording
            }
        }
    }

    private func stopAndProcess() {
        // Stop the timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingStartTime = nil

        viewState = .transcribing

        Task {
            let transcribedText = await voiceInputManager.stopRecording()

            if let text = transcribedText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Success - send the query
                await sendQuery(prompt: text)
            } else {
                // No speech detected - show retry view
                await MainActor.run {
                    viewState = .retryAudio
                }
            }
        }
    }

    private func cancelRecording() {
        // Stop the timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingStartTime = nil

        voiceInputManager.cancelRecording()
        resetToCamera()
    }

    private func retryRecording() {
        Task {
            await voiceInputManager.startRecording()

            // Start the timer
            recordingStartTime = Date()
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let startTime = recordingStartTime {
                    recordingDuration = Date().timeIntervalSince(startTime)
                }
            }

            viewState = .recording
        }
    }

    private func sendQuery(prompt: String) async {
        guard let imageData = cameraManager.capturedImage else { return }

        await MainActor.run {
            viewState = .querying
            lastQueryImageData = imageData
        }

        queryTask = Task {
            do {
                let result = try await queryService.query(image: imageData, prompt: prompt)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    response = result
                    viewState = .response

                    // Save to history
                    historyManager.addToHistory(
                        prompt: prompt,
                        response: result,
                        provider: queryService.currentProvider.displayName,
                        model: queryService.currentModel.displayName,
                        imageData: lastQueryImageData
                    )
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        resetToCamera()
                    }
                }
            }

            await MainActor.run {
                queryTask = nil
            }
        }
    }

    private func cancelQuery() {
        queryTask?.cancel()
        queryTask = nil
        resetToCamera()
    }

    private func resetToCamera() {
        cameraManager.clearCapturedImage()
        response = ""
        recordingDuration = 0
        viewState = .camera
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Pulsing Animation Modifier
struct PulsingAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

#Preview {
    ContentView()
}

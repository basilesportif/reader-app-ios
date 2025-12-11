import SwiftUI

struct ContentView: View {
    @State private var cameraManager = CameraManager()
    @State private var queryService = QueryService()
    @State private var historyManager = HistoryManager()
    @State private var prompt = ""
    @State private var response = ""
    @State private var isQuerying = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var errorMessage: String?
    @State private var lastQueryImageData: Data?

    enum ViewState {
        case camera
        case preview
        case response
    }

    @State private var viewState: ViewState = .camera
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch viewState {
                case .camera:
                    cameraView
                case .preview:
                    previewView
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
    
    private var cameraView: some View {
        VStack {
            if cameraManager.isAuthorized {
                GeometryReader { geometry in
                    CameraPreview(cameraManager: cameraManager)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                Button {
                    Task {
                        if let _ = await cameraManager.capturePhoto() {
                            viewState = .preview
                        }
                    }
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(.gray, lineWidth: 3)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 30)
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
    
    private var previewView: some View {
        VStack {
            if let imageData = cameraManager.capturedImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
            }
            
            TextField("Enter your question...", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .padding()
            
            HStack(spacing: 20) {
                Button("Retake") {
                    cameraManager.clearCapturedImage()
                    prompt = ""
                    viewState = .camera
                }
                .buttonStyle(.bordered)
                
                Button("Send") {
                    sendQuery()
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || isQuerying)
            }
            .padding()
            
            if isQuerying {
                ProgressView("Querying \(queryService.currentModel.displayName)...")
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
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
                    cameraManager.clearCapturedImage()
                    prompt = ""
                    response = ""
                    viewState = .camera
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
    
    private func sendQuery() {
        guard let imageData = cameraManager.capturedImage else { return }

        isQuerying = true
        lastQueryImageData = imageData

        Task {
            do {
                let result = try await queryService.query(image: imageData, prompt: prompt)
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
            } catch {
                errorMessage = error.localizedDescription
            }
            isQuerying = false
        }
    }
}

#Preview {
    ContentView()
}

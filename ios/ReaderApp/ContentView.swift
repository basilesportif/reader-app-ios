import SwiftUI

struct ContentView: View {
    @State private var cameraManager = CameraManager()
    @State private var queryService = QueryService()
    @State private var prompt = ""
    @State private var response = ""
    @State private var isQuerying = false
    @State private var showSettings = false
    @State private var errorMessage: String?
    
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
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Provider", selection: $queryService.currentProvider) {
                        ForEach(ProviderType.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
                ProgressView("Querying \(queryService.currentProvider.displayName)...")
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
        
        Task {
            do {
                let result = try await queryService.query(image: imageData, prompt: prompt)
                response = result
                viewState = .response
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

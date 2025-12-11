import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var claudeKey = ""
    @State private var openAIKey = ""
    @State private var geminiKey = ""
    
    @State private var showClaudeKey = false
    @State private var showOpenAIKey = false
    @State private var showGeminiKey = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Claude (Anthropic)") {
                    apiKeyField(
                        key: $claudeKey,
                        showKey: $showClaudeKey,
                        provider: .claude,
                        placeholder: "sk-ant-..."
                    )
                }
                
                Section("OpenAI") {
                    apiKeyField(
                        key: $openAIKey,
                        showKey: $showOpenAIKey,
                        provider: .openai,
                        placeholder: "sk-..."
                    )
                }
                
                Section("Gemini (Google)") {
                    apiKeyField(
                        key: $geminiKey,
                        showKey: $showGeminiKey,
                        provider: .gemini,
                        placeholder: "AIza..."
                    )
                }
                
                Section {
                    Text("API keys are stored securely in the iOS Keychain.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadKeys()
            }
        }
    }
    
    @ViewBuilder
    private func apiKeyField(
        key: Binding<String>,
        showKey: Binding<Bool>,
        provider: ProviderType,
        placeholder: String
    ) -> some View {
        HStack {
            Group {
                if showKey.wrappedValue {
                    TextField(placeholder, text: key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .onChange(of: key.wrappedValue) { _, newValue in
                if newValue.isEmpty {
                    KeychainManager.deleteKey(for: provider)
                } else {
                    KeychainManager.setKey(newValue, for: provider)
                }
            }
            
            Button {
                showKey.wrappedValue.toggle()
            } label: {
                Image(systemName: showKey.wrappedValue ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func loadKeys() {
        claudeKey = KeychainManager.getKey(for: .claude) ?? ""
        openAIKey = KeychainManager.getKey(for: .openai) ?? ""
        geminiKey = KeychainManager.getKey(for: .gemini) ?? ""
    }
}

#Preview {
    SettingsView()
}

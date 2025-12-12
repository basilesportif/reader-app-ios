import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(QueryService.self) private var queryService

    var body: some View {
        @Bindable var service = queryService

        NavigationStack {
            Form {
                Section("Web Search") {
                    Toggle("Enable web search", isOn: $service.searchEnabled)

                    Stepper(
                        "Results per query: \(service.searchResultsPerQuery)",
                        value: $service.searchResultsPerQuery,
                        in: 1...10
                    )
                }

                Section {
                    Text("When enabled, the app will search the web for relevant information about your image before generating a response.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
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
        }
    }
}

#Preview {
    SettingsView()
        .environment(QueryService())
}

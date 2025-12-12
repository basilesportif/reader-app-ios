import SwiftUI

@main
struct ReaderAppApp: App {
    init() {
        // Configure Worker API key from bundled secrets
        #if SECRETS_AVAILABLE
        WorkerAPIClient.configure(apiKey: Secrets.workerAPIKey)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

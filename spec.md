# Reader App Specification

A personal iOS app for querying book pages using vision-capable LLMs.

## Overview

The Reader App allows positioning a camera over any book page, capturing an image, and running arbitrary queries against it using various AI models (Claude, Gemini, OpenAI). The architecture separates frontend and backend concerns to allow future server-side expansion.

---

## Project Structure

```
reader-app/
├── ios/
│   ├── ReaderApp.xcodeproj
│   └── ReaderApp/
│       ├── ReaderAppApp.swift
│       ├── ContentView.swift
│       ├── SettingsView.swift
│       ├── CameraManager.swift
│       ├── QueryService.swift
│       ├── KeychainManager.swift
│       ├── Providers/
│       │   ├── VisionProvider.swift
│       │   ├── ClaudeProvider.swift
│       │   ├── OpenAIProvider.swift
│       │   └── GeminiProvider.swift
│       └── Info.plist
├── backend/
│   └── README.md
└── spec.md
```

---

## Frontend (iOS App)

### Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Minimum iOS:** 17.0
- **Distribution:** Direct Xcode install or TestFlight (personal use)

### Core Features

1. **Camera Capture**
   - Live camera preview
   - Tap to capture page image
   - Option to retake before sending

2. **Query Interface**
   - Free-form text input for prompts
   - Send image + prompt to selected model
   - Display response with copy to clipboard

3. **Model Selection**
   - Switch between providers (Claude, Gemini, OpenAI)
   - Provider selection persisted via `@AppStorage`

4. **Settings**
   - API key entry for each provider (stored in Keychain)
   - Default provider selection

### Architecture

```
┌─────────────────────────────────────┐
│              Views                  │
├─────────────────────────────────────┤
│  ContentView          SettingsView  │
│  (camera/query/response flow)       │
└──────────────────┬──────────────────┘
                   │
┌──────────────────▼──────────────────┐
│           QueryService              │
├─────────────────────────────────────┤
│  - Holds current provider           │
│  - Processes images                 │
│  - Routes queries to provider       │
│  - Abstracts multi-model support    │
└──────────────────┬──────────────────┘
                   │
┌──────────────────▼──────────────────┐
│            Providers                │
├─────────────────────────────────────┤
│  VisionProvider (protocol)          │
│  ├── ClaudeProvider                 │
│  ├── OpenAIProvider                 │
│  ├── GeminiProvider                 │
│  └── (Future: BackendProvider)      │
└──────────────────┬──────────────────┘
                   │
┌──────────────────▼──────────────────┐
│           KeychainManager           │
└─────────────────────────────────────┘
```

### Provider Protocol

```swift
enum ProviderType: String, CaseIterable {
    case claude, openai, gemini
}

protocol VisionProvider {
    static var providerType: ProviderType { get }
    static var displayName: String { get }
    static func query(image: Data, prompt: String, apiKey: String) async throws -> String
}
```

All providers are stateless with static methods. The `QueryService` manages which provider to use and passes the appropriate API key.

### QueryService

```swift
@Observable
class QueryService {
    var currentProvider: ProviderType

    func query(image: Data, prompt: String) async throws -> String {
        let apiKey = KeychainManager.getKey(for: currentProvider)
        let processedImage = processImage(image) // resize, compress, encode

        switch currentProvider {
        case .claude: return try await ClaudeProvider.query(...)
        case .openai: return try await OpenAIProvider.query(...)
        case .gemini: return try await GeminiProvider.query(...)
        }
    }
}
```

This design allows adding a `.backend` case to `ProviderType` in the future without changing views.

### API Endpoints

**Claude (Anthropic)**
- Endpoint: `https://api.anthropic.com/v1/messages`
- Model: `claude-sonnet-4-20250514`
- Image: base64 in message content

**OpenAI**
- Endpoint: `https://api.openai.com/v1/chat/completions`
- Model: `gpt-4o`
- Image: base64 data URL in content

**Gemini (Google)**
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- Image: inline base64 data

### Files

| File | Purpose |
|------|---------|
| `ReaderAppApp.swift` | App entry point |
| `ContentView.swift` | Main flow: camera → query → response |
| `SettingsView.swift` | API keys and provider selection |
| `CameraManager.swift` | AVFoundation camera capture |
| `QueryService.swift` | Orchestrates providers, processes images |
| `KeychainManager.swift` | Secure API key storage |
| `VisionProvider.swift` | Protocol and ProviderType enum |
| `ClaudeProvider.swift` | Anthropic API |
| `OpenAIProvider.swift` | OpenAI API |
| `GeminiProvider.swift` | Google API |

---

## Backend (Future)

### Purpose
When needed, a backend can:
1. Keep API keys off the device
2. Route requests to multiple providers
3. Add caching, rate limiting, logging
4. Enable complex processing (DSPy, chaining)

### Expected API Contract

```
POST /query
Content-Type: application/json

{
  "image": "<base64>",
  "prompt": "string",
  "provider": "claude" | "openai" | "gemini" (optional),
  "model": "string" (optional)
}

Response:
{
  "response": "string",
  "provider": "string",
  "model": "string"
}
```

### Adding Backend Support

When ready to add a backend:

1. Add `case backend` to `ProviderType`
2. Create `BackendProvider.swift` implementing `VisionProvider`
3. Add backend URL to settings (stored in `@AppStorage`)
4. Update `QueryService` switch to handle `.backend`

No other changes needed - views remain untouched.

---

## Implementation Plan

### Phase 1: Project Setup
- [ ] Create Xcode project in `ios/`
- [ ] Create `backend/README.md` placeholder
- [ ] Configure bundle ID, deployment target (iOS 17)
- [ ] Add camera usage description to Info.plist

### Phase 2: Core Infrastructure
- [ ] Implement `KeychainManager`
- [ ] Define `VisionProvider` protocol and `ProviderType` enum
- [ ] Implement `QueryService` with image processing

### Phase 3: Providers
- [ ] Implement `ClaudeProvider`
- [ ] Implement `OpenAIProvider`
- [ ] Implement `GeminiProvider`

### Phase 4: UI
- [ ] Implement `CameraManager` (AVFoundation)
- [ ] Implement `ContentView` (camera/query/response flow)
- [ ] Implement `SettingsView`

### Phase 5: Polish
- [ ] Error handling and user feedback
- [ ] Test with all three providers

## Technical Notes

### Image Handling
- Resize to max 2048px on longest edge
- Compress JPEG at ~80% quality
- Base64 encode for API transmission

### Privacy
- Images not persisted beyond current session
- API keys stored in iOS Keychain
- No analytics or tracking

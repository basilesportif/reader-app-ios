# Reader App Specification

A personal iOS app for querying book pages using vision-capable LLMs.

## Overview

The Reader App allows positioning a camera over any book page, capturing an image, and running arbitrary queries against it using various AI models (Claude, Gemini, OpenAI). The architecture separates frontend and backend concerns to allow future server-side expansion.

---

## Project Structure

```
reader-app/
├── ios/                    # iOS frontend application
│   └── ReaderApp/
│       ├── App/
│       ├── Views/
│       ├── Models/
│       ├── Services/
│       └── Utilities/
├── backend/                # Backend service (future Cloudflare Worker)
│   └── (placeholder)
├── shared/                 # Shared types/contracts
│   └── api-schema.json     # API contract between frontend and backend
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
   - Image stored temporarily for querying
   - Option to retake before sending

2. **Query Interface**
   - Free-form text input for prompts
   - Send image + prompt to selected model
   - Display streaming or complete response
   - Copy response to clipboard

3. **Model Selection**
   - Switch between providers (Claude, Gemini, OpenAI)
   - Each provider configurable with API key
   - Provider selection persisted

4. **Settings**
   - API key entry for each provider (stored in Keychain)
   - Default provider selection
   - (Future) Backend URL configuration

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                      Views                          │
├─────────────────────────────────────────────────────┤
│  CameraView    QueryView    ResponseView   Settings │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                   Services                          │
├─────────────────────────────────────────────────────┤
│  QueryService (orchestrates requests)               │
│  ImageProcessor (resize, compress, base64 encode)   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                   Providers                         │
├─────────────────────────────────────────────────────┤
│  VisionModelProvider (protocol)                     │
│  ├── ClaudeProvider                                 │
│  ├── GeminiProvider                                 │
│  └── OpenAIProvider                                 │
│  ├── (Future) BackendProvider                       │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                   Utilities                         │
├─────────────────────────────────────────────────────┤
│  KeychainManager                                    │
│  Configuration                                      │
└─────────────────────────────────────────────────────┘
```

### Provider Protocol

```swift
protocol VisionModelProvider {
    var name: String { get }
    var requiresAPIKey: Bool { get }

    func query(image: Data, prompt: String) async throws -> String
    func validate() async throws -> Bool
}
```

### API Endpoints Used

**Claude (Anthropic)**
- Endpoint: `https://api.anthropic.com/v1/messages`
- Model: `claude-sonnet-4-20250514` (or latest vision-capable)
- Image: base64 in message content

**OpenAI**
- Endpoint: `https://api.openai.com/v1/chat/completions`
- Model: `gpt-4o`
- Image: base64 data URL in message content

**Gemini (Google)**
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- Image: inline base64 data

### File Breakdown

| File | Purpose |
|------|---------|
| `ReaderAppApp.swift` | App entry point, environment setup |
| `ContentView.swift` | Main navigation container |
| `CameraView.swift` | Camera preview and capture |
| `CapturePreviewView.swift` | Review captured image before query |
| `QueryView.swift` | Prompt input and submission |
| `ResponseView.swift` | Display model response |
| `SettingsView.swift` | API keys and preferences |
| `VisionModelProvider.swift` | Provider protocol definition |
| `ClaudeProvider.swift` | Anthropic API implementation |
| `OpenAIProvider.swift` | OpenAI API implementation |
| `GeminiProvider.swift` | Google API implementation |
| `QueryService.swift` | Orchestrates image + prompt → response |
| `ImageProcessor.swift` | Image resizing, compression, encoding |
| `KeychainManager.swift` | Secure API key storage |
| `Configuration.swift` | App configuration and defaults |

---

## Backend (Future)

### Purpose
The backend exists to:
1. Keep API keys off the device
2. Route requests to multiple providers
3. Add caching, rate limiting, logging
4. Enable more complex processing (DSPy, chaining)

### Placeholder Structure

```
backend/
├── README.md           # Setup instructions (future)
├── wrangler.toml       # Cloudflare Worker config (future)
└── src/
    └── index.ts        # Worker entry point (future)
```

For now, the backend directory contains only placeholder files documenting the intended future architecture.

### Future API Contract

When the backend is implemented, the iOS app will call it instead of direct model APIs:

```
POST /query
Content-Type: application/json

{
  "image": "<base64>",
  "prompt": "string",
  "provider": "claude" | "openai" | "gemini",
  "model": "string (optional)"
}

Response:
{
  "response": "string",
  "provider": "string",
  "model": "string",
  "usage": { ... }
}
```

The iOS app includes a `BackendProvider` that conforms to `VisionModelProvider` but routes through a configurable backend URL. This is disabled by default but can be enabled when the backend is deployed.

---

## Shared Contract

### `shared/api-schema.json`

JSON Schema defining the request/response contract between frontend and backend. This ensures consistency when the backend is eventually implemented.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "definitions": {
    "QueryRequest": {
      "type": "object",
      "properties": {
        "image": { "type": "string", "description": "Base64 encoded image" },
        "prompt": { "type": "string" },
        "provider": { "enum": ["claude", "openai", "gemini"] },
        "model": { "type": "string" }
      },
      "required": ["image", "prompt"]
    },
    "QueryResponse": {
      "type": "object",
      "properties": {
        "response": { "type": "string" },
        "provider": { "type": "string" },
        "model": { "type": "string" },
        "usage": { "type": "object" }
      },
      "required": ["response"]
    }
  }
}
```

---

## Implementation Plan

### Phase 1: Project Setup
- [ ] Create iOS project structure in `ios/ReaderApp`
- [ ] Create backend placeholder in `backend/`
- [ ] Create shared schema in `shared/`
- [ ] Configure iOS project (bundle ID, permissions, deployment target)
- [ ] Add camera usage description to Info.plist

### Phase 2: Core Infrastructure
- [ ] Implement `KeychainManager` for secure API key storage
- [ ] Implement `Configuration` for app settings
- [ ] Implement `ImageProcessor` for image handling
- [ ] Define `VisionModelProvider` protocol

### Phase 3: Provider Implementations
- [ ] Implement `ClaudeProvider`
- [ ] Implement `OpenAIProvider`
- [ ] Implement `GeminiProvider`
- [ ] Implement `BackendProvider` (disabled, for future use)
- [ ] Implement `QueryService` to orchestrate providers

### Phase 4: UI Implementation
- [ ] Implement `CameraView` with live preview
- [ ] Implement `CapturePreviewView` for image review
- [ ] Implement `QueryView` for prompt input
- [ ] Implement `ResponseView` for displaying results
- [ ] Implement `SettingsView` for configuration
- [ ] Implement `ContentView` as main navigation

### Phase 5: Integration & Polish
- [ ] Wire up all views with navigation
- [ ] Add error handling and user feedback
- [ ] Test with all three providers
- [ ] Handle edge cases (no camera, no API key, network errors)

---

## Technical Notes

### Image Handling
- Capture at reasonable resolution (not full camera resolution)
- Compress JPEG at ~80% quality to reduce payload size
- Max dimension ~2048px (sufficient for text legibility)
- Base64 encode for API transmission

### Error Handling
- Network errors: retry with exponential backoff
- API errors: display provider-specific error messages
- Invalid API key: prompt to check settings
- Rate limiting: inform user and suggest waiting

### Privacy
- Images are not persisted beyond the current session
- API keys stored in iOS Keychain (encrypted)
- No analytics or tracking
- All processing via direct API calls (no intermediary servers until backend is added)

---

## Future Enhancements (Out of Scope for v1)

- Prompt templates / saved queries
- Query history with searchable archive
- Multi-page capture and context
- OCR preprocessing
- Offline text extraction
- iCloud sync for settings
- Share extension for importing images
- Widget for quick capture

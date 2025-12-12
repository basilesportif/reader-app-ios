# Implementation Plan: Image Web Search Feature

## Overview

When a user uploads an image and asks a question, the system will automatically perform web searches on relevant aspects of the image to provide more informed answers. This adds contextual web knowledge to vision-based queries.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        New Query Flow                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. [Image + Prompt + searchEnabled + searchResultsPerQuery] arrive  │
│              │                                                       │
│              ▼                                                       │
│  2. If searchEnabled:                                                │
│     ├─► Extraction call (same provider/model as user selected):     │
│     │   "Given this image and question: {prompt}                    │
│     │    What 1-3 search queries would help answer this?"           │
│     │   Returns: JSON array of search query strings                 │
│     │              │                                                │
│     │              ▼                                                │
│     ├─► Brave Search API (parallel queries)                         │
│     │   - searchResultsPerQuery results per query                   │
│     │   - Returns: structured search results                        │
│     │              │                                                │
│     │              ▼                                                │
│     └─► Build enhanced prompt with search context                   │
│              │                                                       │
│              ▼                                                       │
│  3. Final call to user's chosen provider/model:                      │
│     [Image + Enhanced Prompt with Search Context] → Answer           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Decisions

1. **Search Provider:** Brave Search API (swappable in worker)
2. **iOS Architecture:** Refactor to route ALL queries through the worker (removes direct provider API calls from iOS)
3. **Deployment:** GitHub Actions workflow for automatic Cloudflare Worker deployment

## API Changes

### Worker `/api/query` Request

```typescript
interface QueryRequest {
  image: string;              // base64 (existing)
  prompt: string;             // (existing)
  provider: Provider;         // (existing)
  model?: Model;              // (existing)
  searchEnabled?: boolean;    // NEW - default: true
  searchResultsPerQuery?: number; // NEW - default: 5, range: 1-10
}
```

### Worker `/api/query` Response

```typescript
interface QueryResponse {
  response: string;           // (existing)
  provider: string;           // (existing)
  model: string;              // (existing)
  searchQueries?: string[];   // NEW - queries that were searched (for transparency)
  searchPerformed?: boolean;  // NEW - whether search was actually done
}
```

## Implementation Steps

### Phase 1: Worker Changes (`worker/src/index.ts`)

#### 1.1 Add Brave Search API Key to Environment
- Add `BRAVE_SEARCH_API_KEY: string` to `Env` interface
- Update `wrangler.toml` comments to document required secret
- Create `.dev.vars.example` with placeholder

#### 1.2 Create Search Query Extraction Function
```typescript
async function extractSearchQueries(
  image: string,
  prompt: string,
  provider: Provider,
  model: Model | undefined,
  env: Env
): Promise<string[]>
```
- Uses the same provider/model the user selected
- System prompt instructs model to return 1-3 JSON search queries
- Parses response to extract query array

#### 1.3 Create Brave Search Function
```typescript
interface SearchResult {
  query: string;
  title: string;
  snippet: string;
  url: string;
}

async function searchBrave(
  queries: string[],
  resultsPerQuery: number,
  apiKey: string
): Promise<SearchResult[]>
```
- Calls Brave Web Search API: `https://api.search.brave.com/res/v1/web/search`
- Parallel requests for each query
- Returns structured results with title, snippet, URL

#### 1.4 Create Search Context Builder
```typescript
function buildSearchContext(results: SearchResult[]): string
```
- Formats search results as markdown
- Groups by query
- Includes source URLs

#### 1.5 Modify Main Query Flow
- Parse new `searchEnabled` (default: true) and `searchResultsPerQuery` (default: 5) from request
- If search enabled:
  1. Call `extractSearchQueries()`
  2. Call `searchBrave()`
  3. Build enhanced prompt with search context
- Call existing provider query with enhanced prompt
- Return search metadata in response

### Phase 2: iOS App Refactor (Route Through Worker)

#### 2.1 Create Worker API Client
File: `ios/ReaderApp/Services/WorkerAPIClient.swift` (new)
```swift
struct WorkerAPIClient {
    static let baseURL = URL(string: "https://reader-app-api.<your-subdomain>.workers.dev")!

    static func query(
        image: Data,
        prompt: String,
        provider: ProviderType,
        model: ModelType,
        searchEnabled: Bool,
        searchResultsPerQuery: Int
    ) async throws -> QueryResponse

    static func transcribe(audio: Data, format: String) async throws -> String
}
```

#### 2.2 Update QueryService
File: `ios/ReaderApp/QueryService.swift`
- Add search settings properties:
```swift
var searchEnabled: Bool {
    didSet { UserDefaults.standard.set(searchEnabled, forKey: "searchEnabled") }
}
var searchResultsPerQuery: Int {
    didSet { UserDefaults.standard.set(searchResultsPerQuery, forKey: "searchResultsPerQuery") }
}
```
- Default `searchEnabled = true`
- Default `searchResultsPerQuery = 5`
- Replace direct provider calls with `WorkerAPIClient.query()`

#### 2.3 Simplify Provider Files
Files: `ios/ReaderApp/Providers/*.swift`
- Remove `ClaudeProvider.swift`, `OpenAIProvider.swift`, `GeminiProvider.swift`
- Keep `VisionProvider.swift` for type definitions only (ProviderType, ModelType, ProviderError)

#### 2.4 Remove API Keys from iOS Keychain
- Since all calls go through worker, iOS no longer needs provider API keys
- Update `SettingsView.swift` to remove API key fields
- Update `KeychainManager.swift` or remove if no longer needed
- Worker URL could be configurable for development

#### 2.5 Update SettingsView
File: `ios/ReaderApp/SettingsView.swift`
- Remove API key sections (Claude, OpenAI, Gemini)
- Add new "Search" section:
  - Toggle for "Enable web search" (default: on)
  - Stepper for "Results per query" (1-10, default: 5)
- Optionally add "Worker URL" field for development/testing

### Phase 3: Web App Changes

#### 3.1 Add Search Settings Hook
File: `web/src/hooks/useSearchSettings.ts` (new)
```typescript
const STORAGE_KEY_SEARCH_ENABLED = 'reader-app-search-enabled'
const STORAGE_KEY_RESULTS_PER_QUERY = 'reader-app-search-results-per-query'

export function useSearchSettings() {
  const [searchEnabled, setSearchEnabled] = useState(() => {
    const stored = localStorage.getItem(STORAGE_KEY_SEARCH_ENABLED)
    return stored !== null ? stored === 'true' : true // default: true
  })

  const [searchResultsPerQuery, setSearchResultsPerQuery] = useState(() => {
    const stored = localStorage.getItem(STORAGE_KEY_RESULTS_PER_QUERY)
    return stored !== null ? parseInt(stored, 10) : 5 // default: 5
  })

  // Persist changes...
  return { searchEnabled, searchResultsPerQuery, setSearchEnabled, setSearchResultsPerQuery }
}
```

#### 3.2 Update API Service
File: `web/src/services/api.ts`
- Add `searchEnabled` and `searchResultsPerQuery` parameters to `queryApi()`
- Update `QueryResponse` interface with search metadata

#### 3.3 Update UI
File: `web/src/App.tsx` or `web/src/components/QueryInterface.tsx`
- Add settings UI for search toggle and results count
- Could be inline toggles near the query input or in a settings panel

### Phase 4: GitHub Actions Deployment

#### 4.1 Create Deployment Workflow
File: `.github/workflows/deploy-worker.yml` (new)
```yaml
name: Deploy Worker

on:
  push:
    branches: [main]
    paths:
      - 'worker/**'
      - '.github/workflows/deploy-worker.yml'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        working-directory: ./worker
        run: npm install

      - name: Deploy to Cloudflare Workers
        working-directory: ./worker
        run: npx wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

#### 4.2 Required GitHub Secrets
- `CLOUDFLARE_API_TOKEN`: API token with Workers edit permissions

#### 4.3 Required Cloudflare Worker Secrets
Set via `wrangler secret put <NAME>`:
- `CLAUDE_API_KEY`
- `OPENAI_API_KEY`
- `GEMINI_API_KEY`
- `BRAVE_SEARCH_API_KEY`

#### 4.4 Update wrangler.toml
```toml
name = "reader-app-api"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[vars]
# Non-secret config vars go here

# Secrets are set via: wrangler secret put <SECRET_NAME>
# Required secrets:
# - CLAUDE_API_KEY
# - OPENAI_API_KEY
# - GEMINI_API_KEY
# - BRAVE_SEARCH_API_KEY
```

### Phase 5: Testing & Polish

#### 5.1 Test Cases
- Image with recognizable product → should search for product info
- Image with landmark → should search for location info
- Image with text/document → should search for related topics
- Search disabled → should skip search, behave as before
- Various `searchResultsPerQuery` values
- iOS app works entirely through worker
- Web app works with search enabled/disabled

#### 5.2 Error Handling
- Brave Search API failure → graceful degradation (proceed without search)
- Extraction returns no queries → proceed without search
- Invalid JSON from extraction → retry once or proceed without search
- Worker unreachable → show appropriate error to user

#### 5.3 Response Display
- Optionally show user what was searched (transparency)
- Could show "Searched for: X, Y, Z" in response metadata

## File Changes Summary

| File | Changes |
|------|---------|
| `worker/src/index.ts` | Add Brave Search integration, search extraction, enhanced flow |
| `worker/wrangler.toml` | Document BRAVE_SEARCH_API_KEY secret |
| `worker/.dev.vars.example` | Create with placeholder for all secrets |
| `.github/workflows/deploy-worker.yml` | NEW - Cloudflare deployment workflow |
| `ios/ReaderApp/Services/WorkerAPIClient.swift` | NEW - Worker API client |
| `ios/ReaderApp/QueryService.swift` | Add search settings, use WorkerAPIClient |
| `ios/ReaderApp/SettingsView.swift` | Remove API keys, add search settings UI |
| `ios/ReaderApp/Providers/ClaudeProvider.swift` | DELETE |
| `ios/ReaderApp/Providers/OpenAIProvider.swift` | DELETE |
| `ios/ReaderApp/Providers/GeminiProvider.swift` | DELETE |
| `ios/ReaderApp/Providers/VisionProvider.swift` | Keep for type definitions only |
| `ios/ReaderApp/KeychainManager.swift` | DELETE or simplify |
| `web/src/hooks/useSearchSettings.ts` | NEW - search settings hook |
| `web/src/services/api.ts` | Add search params to API call |
| `web/src/App.tsx` | Add search settings UI |

## Environment Variables

### Worker (Cloudflare Secrets)
```
CLAUDE_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AIza...
BRAVE_SEARCH_API_KEY=BSA...
```

### GitHub Actions Secrets
```
CLOUDFLARE_API_TOKEN=...
```

## Search Context Format

The search results will be injected into the prompt like this:

```
[User's original prompt]

---
**Web Search Context:**

Search: "iPhone 15 Pro Max price 2024"
- iPhone 15 Pro Max - Apple: Starting at $1,199 for 256GB... (apple.com)
- iPhone 15 Pro Max Review: Best iPhone camera yet... (techradar.com)

Search: "iPhone 15 Pro Max vs Samsung S24"
- iPhone 15 Pro Max vs Galaxy S24 Ultra: Which flagship wins?... (tomsguide.com)
- Camera comparison: iPhone 15 Pro Max vs Samsung S24 Ultra... (dxomark.com)

---
Please answer the question using both the image and the search context above.
```

## Brave Search API Reference

Endpoint: `https://api.search.brave.com/res/v1/web/search`

Request:
```
GET /res/v1/web/search?q={query}&count={resultsPerQuery}
Headers:
  X-Subscription-Token: {BRAVE_SEARCH_API_KEY}
  Accept: application/json
```

Response structure:
```json
{
  "web": {
    "results": [
      {
        "title": "...",
        "url": "...",
        "description": "..."
      }
    ]
  }
}
```

## Estimated Brave Search Costs

- Brave Search API: Free tier available (2,000 queries/month)
- Paid: $5/1000 queries after free tier
- With 3 queries per image query: ~$0.015 per user query on paid tier
- Free tier sufficient for development and light usage

## Migration Notes

### iOS App Migration
1. Users will lose stored API keys (they're no longer needed)
2. First launch after update should work seamlessly - defaults to worker
3. Consider showing a one-time migration notice explaining the change

### Breaking Changes
- iOS app will require network access to worker (was previously optional for direct API)
- API keys are now centralized in worker, not per-device

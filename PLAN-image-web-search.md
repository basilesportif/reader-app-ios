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
│     ├─► Tavily search (parallel queries)                            │
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

#### 1.1 Add Tavily API Key to Environment
- Add `TAVILY_API_KEY: string` to `Env` interface
- Document in `.dev.vars.example` (create if doesn't exist)

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

#### 1.3 Create Tavily Search Function
```typescript
async function searchTavily(
  queries: string[],
  resultsPerQuery: number,
  apiKey: string
): Promise<SearchResult[]>
```
- Calls Tavily Search API in parallel for each query
- Returns structured results with title, snippet, URL

#### 1.4 Create Search Context Builder
```typescript
function buildSearchContext(results: SearchResult[]): string
```
- Formats search results as markdown
- Groups by query
- Includes source URLs

#### 1.5 Modify Main Query Flow
- Parse new `searchEnabled` and `searchResultsPerQuery` from request
- If search enabled:
  1. Call `extractSearchQueries()`
  2. Call `searchTavily()`
  3. Prepend search context to prompt
- Call existing provider query with enhanced prompt
- Return search metadata in response

### Phase 2: iOS App Changes

#### 2.1 Add Search Settings to QueryService
File: `ios/ReaderApp/QueryService.swift`
```swift
var searchEnabled: Bool {
    didSet {
        UserDefaults.standard.set(searchEnabled, forKey: "searchEnabled")
    }
}

var searchResultsPerQuery: Int {
    didSet {
        UserDefaults.standard.set(searchResultsPerQuery, forKey: "searchResultsPerQuery")
    }
}
```
- Default `searchEnabled = true`
- Default `searchResultsPerQuery = 5`
- Load from UserDefaults in `init()`

#### 2.2 Update Provider Calls
Files: `ios/ReaderApp/Providers/*.swift`
- Add `searchEnabled` and `searchResultsPerQuery` parameters to query methods
- Pass to worker API (or handle locally if using direct API calls)

**Decision needed:** iOS currently calls provider APIs directly. Options:
1. Route through worker (adds network hop but centralizes logic)
2. Duplicate search logic in iOS (more code but faster for direct API users)

**Recommendation:** Route through worker. Simpler, single source of truth.

#### 2.3 Update SettingsView
File: `ios/ReaderApp/SettingsView.swift`
- Add new "Search" section with:
  - Toggle for "Enable web search" (default: on)
  - Stepper/Picker for "Results per query" (1-10, default: 5)

### Phase 3: Web App Changes

#### 3.1 Add Search Settings Hook
File: `web/src/hooks/useSearchSettings.ts` (new)
```typescript
export function useSearchSettings() {
  const [searchEnabled, setSearchEnabled] = useState(true)
  const [searchResultsPerQuery, setSearchResultsPerQuery] = useState(5)
  // Persist to localStorage
  // ...
}
```

#### 3.2 Update API Service
File: `web/src/services/api.ts`
- Add `searchEnabled` and `searchResultsPerQuery` to `queryApi()` function
- Update `QueryResponse` interface with search metadata

#### 3.3 Update UI
File: `web/src/App.tsx` or relevant component
- Add settings UI for search toggle and results count
- Could be in a settings panel/modal or inline with other controls

### Phase 4: Testing & Polish

#### 4.1 Test Cases
- Image with recognizable product → should search for product info
- Image with landmark → should search for location info
- Image with text/document → should search for related topics
- Search disabled → should skip search, behave as before
- Various `searchResultsPerQuery` values

#### 4.2 Error Handling
- Tavily API failure → graceful degradation (proceed without search)
- Extraction returns no queries → proceed without search
- Invalid JSON from extraction → retry once or proceed without search

#### 4.3 Response Display
- Optionally show user what was searched (transparency)
- Could show "Searched for: X, Y, Z" in response metadata

## File Changes Summary

| File | Changes |
|------|---------|
| `worker/src/index.ts` | Add Tavily integration, search extraction, enhanced flow |
| `worker/.dev.vars.example` | Document TAVILY_API_KEY |
| `ios/ReaderApp/QueryService.swift` | Add search settings properties |
| `ios/ReaderApp/SettingsView.swift` | Add search settings UI |
| `ios/ReaderApp/Providers/*.swift` | Pass search params (if routing through worker) |
| `web/src/hooks/useSearchSettings.ts` | New hook for search settings |
| `web/src/services/api.ts` | Add search params to API call |
| `web/src/App.tsx` | Add search settings UI |

## Environment Variables

```
TAVILY_API_KEY=tvly-...
```

## Search Context Format

The search results will be injected into the prompt like this:

```
[User's original prompt]

---
**Web Search Context:**

Search: "iPhone 15 Pro Max price 2024"
• iPhone 15 Pro Max - Apple: Starting at $1,199 for 256GB... (apple.com)
• iPhone 15 Pro Max Review: Best iPhone camera yet... (techradar.com)

Search: "iPhone 15 Pro Max vs Samsung S24"
• iPhone 15 Pro Max vs Galaxy S24 Ultra: Which flagship wins?... (tomsguide.com)
• Camera comparison: iPhone 15 Pro Max vs Samsung S24 Ultra... (dxomark.com)

---
Please answer the question using both the image and the search context above.
```

## Open Questions

1. **Rate limiting:** Should we add any rate limiting for search to control costs?
2. **Caching:** Should identical queries within a session reuse search results?
3. **Search provider fallback:** If Tavily fails, try another provider?

## Estimated Tavily Costs

- Tavily API: ~$0.003 per search
- With 3 queries per image query: ~$0.009 per user query
- Reasonable for the value added

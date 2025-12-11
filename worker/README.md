# Reader App API Worker

Cloudflare Worker that proxies requests to AI vision APIs, keeping API keys secure on the server.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set your API keys as secrets:
   ```bash
   wrangler secret put CLAUDE_API_KEY
   wrangler secret put OPENAI_API_KEY
   wrangler secret put GEMINI_API_KEY
   ```

3. Deploy:
   ```bash
   npm run deploy
   ```

## Local Development

```bash
npm run dev
```

This starts the worker locally at http://localhost:8787

## API

### POST /api/query

```json
{
  "image": "<base64 encoded image>",
  "prompt": "What text is on this page?",
  "provider": "claude" | "openai" | "gemini"
}
```

Response:
```json
{
  "response": "The text says...",
  "provider": "claude",
  "model": "claude-sonnet-4-20250514"
}
```

### GET /api/health

Returns `{ "status": "ok" }`
